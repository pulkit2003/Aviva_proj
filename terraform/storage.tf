# S3 bucket where EC2 will upload the .txt file

resource "aws_s3_bucket" "storage" {
  bucket = "${var.project_name}-${var.region}-bucket"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}
