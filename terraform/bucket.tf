resource "aws_s3_bucket" "my_bucket" {
  bucket = "bucketforfronend070623"  

  tags = {
    Name        = "MyBucket"
    Environment = "Development"
  }

}

resource "aws_s3_bucket_website_configuration" "my_bucket_website" {
  bucket = aws_s3_bucket.my_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.example]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.my_bucket.id}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_object" "my_file" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "index.html"
  source = "index.html"
  content_type = "text/html"
  content_disposition = "inline"
  depends_on = [aws_s3_bucket.my_bucket]
}

resource "aws_s3_object" "js" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "service-worker.js"  # Replace with your desired key (file name)

  content_type = "text/javascript"
  source       = "service-worker.js"
  content_disposition = "inline"
  depends_on = [aws_s3_bucket.my_bucket]
}
