resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.my_bucket.bucket_domain_name}"
    origin_id   = "website"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  
  aliases = ["ysahakyan.devopsaca.site"]

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = "website"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.ycert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
    #cloudfront_default_certificate = true
  }

}

resource "aws_route53_record" "cloudfront_record" {
  zone_id = data.aws_route53_zone.existing_zone.zone_id
  name    = "ysahakyan.devopsaca.site"
  type    = "A"
  alias {
    name                   = "${aws_cloudfront_distribution.my_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.my_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}
