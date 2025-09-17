data "archive_file" "app" {
  type             = "zip"
  source_dir       = "${path.module}/app"
  output_file_mode = "0666"
  output_path      = "${path.module}/app.tgz"
}

resource "google_storage_bucket" "bucket" {
  name                        = "cloud-app-sources-123"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
  location                    = "US"
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "archive" {
  name   = "app-${data.archive_file.app.id}"
  bucket = google_storage_bucket.bucket.name
  source = "${path.module}/app.tgz"
}

resource "google_storage_bucket_object" "index" {
  name   = "index1234.html"
  bucket = google_storage_bucket.bucket.name
  source = "${path.module}/static/index.html"
  cache_control = "no-cache,max-age=0"
}

resource "google_storage_bucket_object" "icon" {
  name   = "favicon.jpg"
  bucket = google_storage_bucket.bucket.name
  source = "${path.module}/static/favicon.jpg"
}

resource "google_compute_backend_bucket" "static_files" {
  name        = "${var.name}-static-files"
  description = "Contains static files"
  bucket_name = google_storage_bucket.bucket.name
  enable_cdn  = false
}

resource "google_cloudfunctions2_function" "function" {
  name     = "test-function-123"
  location = "us-central1"
  build_config {
    runtime     = "python313"
    entry_point = "hello_get"

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    min_instance_count = 0
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    ingress_settings   = "ALLOW_INTERNAL_AND_GCLB"
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  project  = google_cloudfunctions2_function.function.project
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "allUsers" # TODO: Replace this with a service account
}

resource "google_compute_region_network_endpoint_group" "function_neg" {
  name                  = "function-neg"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_function {
    function = google_cloudfunctions2_function.function.name
  }
}

resource "google_compute_security_policy" "security_policy" {
  name        = "security-policy"
  description = "Allow access from my ip"
  type        = "CLOUD_ARMOR"
  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["73.214.231.6/32"]
      }
    }
    description = "Allow traffic from my laptop's IP"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default Rule"
  }
}

resource "google_compute_backend_service" "serverless_backend_service" {
  name                  = "my-serverless-backend-service"
  protocol              = "HTTPS"            # Or HTTP depending on your load balancer
  load_balancing_scheme = "EXTERNAL_MANAGED" # Or INTERNAL_MANAGED for internal load balancers
  backend {
    group = google_compute_region_network_endpoint_group.function_neg.id
  }
  security_policy = google_compute_security_policy.security_policy.self_link
}

resource "google_compute_url_map" "url_map" {
  name            = "my-url-map"
  default_service = google_compute_backend_service.serverless_backend_service.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "mysite"

  }

  path_matcher {
    name            = "mysite"
    default_service = google_compute_backend_service.serverless_backend_service.id

    path_rule {
      paths   = ["/"]
      service = google_compute_backend_service.serverless_backend_service.id
    }

    path_rule {
      paths = ["/index1234.html", "/favicon.ico"]
      service = google_compute_backend_bucket.static_files.id
    }    
  }


  test {
    service = google_compute_backend_service.serverless_backend_service.id
    host    = var.domain
    path    = "/"
  }
}

resource "google_compute_global_address" "default" {
  name = "test-address"
}

resource "google_compute_managed_ssl_certificate" "default" {
  count = var.test ? 0 : 1
  name  = "test-cert"
  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "my-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [var.test ? google_compute_ssl_certificate.default[0].id : google_compute_managed_ssl_certificate.default[0].id]
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.name}-https-redirect-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  name = "${var.name}-url-map"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_global_forwarding_rule" "forwarding_rule_https" {
  name                  = "${var.name}-https-forwarding-rule"
  target                = google_compute_target_https_proxy.https_proxy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "443"
  ip_address            = google_compute_global_address.default.address
}

resource "google_compute_global_forwarding_rule" "forwarding_rule_http" {
  name                  = "${var.name}-http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "80"
  ip_address            = google_compute_global_address.default.address
}

data "google_dns_managed_zone" "zone" {
  name = "testing"
}

resource "google_dns_record_set" "frontend" {
  name         = "${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "testing"
  rrdatas      = [google_compute_global_address.default.address]
}
