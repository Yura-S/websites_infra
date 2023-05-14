provider "aws" {
  
  region = "us-east-1"

  default_tags {
    tags = {
      Owner     = "yura"
      Type      = "prod"
    }
  }
}
