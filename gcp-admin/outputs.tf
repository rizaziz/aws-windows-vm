output "lb_ip" {
  value = google_compute_global_address.default.address
}

output "frontend_url" {
  value = "https://${var.domain}"
}