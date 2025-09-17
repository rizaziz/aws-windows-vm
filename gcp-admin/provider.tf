terraform {
  required_version = " ~> 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.49"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "google" {
  project = "admin-143286579"
  region  = "us-central1"
}
