resource "tls_private_key" "default" {
  count     = var.test ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  count           = var.test ? 1 : 0
  private_key_pem = tls_private_key.default[0].private_key_pem

  # Certificate expires after 12 hours.
  validity_period_hours = 12

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 3

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  #   dns_names = ["example.com"]
  ip_addresses = [google_compute_global_address.default.address]

  subject {
    common_name = var.domain
    # organization = "ACME Examples, Inc"
  }
}

resource "random_id" "certificate" {
  count       = var.test ? 1 : 0
  byte_length = 4
  prefix      = "my-certificate-"

  # For security, do not expose raw certificate values in the output
  keepers = {
    private_key = tls_private_key.default[0].private_key_pem
    certificate = tls_self_signed_cert.default[0].cert_pem
  }
}

resource "google_compute_ssl_certificate" "default" {
  count       = var.test ? 1 : 0
  name        = random_id.certificate[0].hex
  private_key = tls_private_key.default[0].private_key_pem
  certificate = tls_self_signed_cert.default[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }
}
