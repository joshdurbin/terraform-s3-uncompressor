variable "source_s3_bucket_name" {
  description = "Bucket to which compressed files will be uploaded (will be created, so the bucket cannot exist already!)"
}

variable "destination_s3_bucket_name" {
  description = "Bucket to which contents of uncompressed files will be written to. Use the same value as in SourceBucketName to uncompress to the same bucket where file was uploaded, however keep in mind that using the same bucket as a destination will recursively uncompress all of the files that were inside uploaded archive."
}

variable "lambda_memory_size" {
  description = "Amount of memory dedicated for Lambda function (the more, the bigger archive it will be able to uncompress)"
  default     = 128
}

variable "lambda_timeout" {
  description = "Maximum time for how long Lambda can be runing"
  default     = 60
}

variable "lambda_invocation_required_prefix" {
  type        = "string"
  description = ""
  default     = ".zip"
}
