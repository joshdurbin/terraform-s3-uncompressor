# terraform-s3-uncompressor
A terraform module that supports extracting zip files from one s3 bucket into a destination s3 bucket.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| destination\_s3\_bucket\_name | Bucket to which contents of uncompressed files will be written to. Use the same value as in SourceBucketName to uncompress to the same bucket where file was uploaded, however keep in mind that using the same bucket as a destination will recursively uncompress all of the files that were inside uploaded archive. | string | - | yes |
| source\_s3\_bucket\_name | Bucket to which compressed files will be uploaded (will be created, so the bucket cannot exist already!) | string | - | yes |
| lambda\_invocation\_required\_prefix | - | string | `.zip` | no |
| lambda\_memory\_size | Amount of memory dedicated for Lambda function (the more, the bigger archive it will be able to uncompress) | string | `128` | no |
| lambda\_timeout | Maximum time for how long Lambda can be runing | string | `60` | no |
