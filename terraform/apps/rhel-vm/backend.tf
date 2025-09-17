terraform {
  backend "s3" {
    bucket       = "tf-app-states"
    key          = "rhel-vm-app-tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}
