locals {
  zip_target_name = "s3_uncompressor.zip"
  function_name   = "s3_uncompressor"
  lambda_runtime  = "python3.6"
}

data "archive_file" "zip_archive" {
  type        = "zip"
  source_dir  = "${path.module}/s3_uncompressor"
  output_path = "${path.module}/${local.zip_target_name}"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*",
    ]
  }

  statement {
    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      "${aws_sqs_queue.dead_letter_que.arn}",
    ]
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${data.aws_s3_bucket.destination_bucket.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  role   = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy = "${data.aws_iam_policy_document.lambda_policy.json}"
}

data "aws_s3_bucket" "source_bucket" {
  bucket = "${var.source_s3_bucket_name}"
}

data "aws_s3_bucket" "destination_bucket" {
  bucket = "${var.destination_s3_bucket_name}"
}

data "aws_iam_policy_document" "iam_for_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_terraform_lambda" {
  assume_role_policy = "${data.aws_iam_policy_document.iam_for_lambda.json}"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
  role       = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "allow_terraform_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.canary_sensor_api_capture.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${data.aws_s3_bucket.source_bucket.arn}"
}

resource "aws_sqs_queue" "dead_letter_que" {
  name = "dead_letter_que"
}

resource "aws_lambda_function" "canary_sensor_api_capture" {
  filename         = "${path.module}/${local.zip_target_name}"
  description      = "Uncompresses files uploaded to the S3 bucket"
  function_name    = "${local.function_name}"
  role             = "${aws_iam_role.iam_for_terraform_lambda.arn}"
  handler          = "lambda_handler"
  source_code_hash = "${data.archive_file.zip_archive.output_base64sha256}"
  runtime          = "${local.lambda_runtime}"
  timeout          = "${var.lambda_timeout}"
  memory_size      = "${var.lambda_memory_size}"

  dead_letter_config {
    target_arn = "${aws_sqs_queue.dead_letter_que.arn}"
  }

  environment {
    variables {
      dest_bucket = "${var.destination_s3_bucket_name}"
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = "${data.aws_s3_bucket.source_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.canary_sensor_api_capture.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = "${var.lambda_invocation_required_prefix}"
  }
}
