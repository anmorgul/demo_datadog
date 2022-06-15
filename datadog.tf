
resource "aws_iam_policy" "dd_integration_policy" {
 name = "DatadogAWSIntegrationPolicy"
 path = "/"
 description = "DatadogAWSIntegrationPolicy"

 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
 {
 "Action": [
    "apigateway:GET",
    "autoscaling:Describe*",
    "backup:List*",
    "budgets:ViewBudget",
    "cloudfront:GetDistributionConfig",
    "cloudfront:ListDistributions",
    "cloudtrail:DescribeTrails",
    "cloudtrail:GetTrailStatus",
    "cloudtrail:LookupEvents",
    "cloudwatch:Describe*",
    "cloudwatch:Get*",
    "cloudwatch:List*",
    "codedeploy:List*",
    "codedeploy:BatchGet*",
    "directconnect:Describe*",
    "dynamodb:List*",
    "dynamodb:Describe*",
    "ec2:Describe*",
    "ecs:Describe*",
    "ecs:List*",
    "elasticache:Describe*",
    "elasticache:List*",
    "elasticfilesystem:DescribeFileSystems",
    "elasticfilesystem:DescribeTags",
    "elasticfilesystem:DescribeAccessPoints",
    "elasticloadbalancing:Describe*",
    "elasticmapreduce:List*",
    "elasticmapreduce:Describe*",
    "es:ListTags",
    "es:ListDomainNames",
    "es:DescribeElasticsearchDomains",
    "fsx:DescribeFileSystems",
    "fsx:ListTagsForResource",
    "health:DescribeEvents",
    "health:DescribeEventDetails",
    "health:DescribeAffectedEntities",
    "kinesis:List*",
    "kinesis:Describe*",
    "lambda:GetPolicy",
    "lambda:List*",
    "logs:DeleteSubscriptionFilter",
    "logs:DescribeLogGroups",
    "logs:DescribeLogStreams",
    "logs:DescribeSubscriptionFilters",
    "logs:FilterLogEvents",
    "logs:PutSubscriptionFilter",
    "logs:TestMetricFilter",
    "organizations:DescribeOrganization",
    "rds:Describe*",
    "rds:List*",
    "redshift:DescribeClusters",
    "redshift:DescribeLoggingStatus",
    "route53:List*",
    "s3:GetBucketLogging",
    "s3:GetBucketLocation",
    "s3:GetBucketNotification",
    "s3:GetBucketTagging",
    "s3:ListAllMyBuckets",
    "s3:PutBucketNotification",
    "ses:Get*",
    "sns:List*",
    "sns:Publish",
    "sqs:ListQueues",
    "states:ListStateMachines",
    "states:DescribeStateMachine",
    "support:DescribeTrustedAdvisor*",
    "support:RefreshTrustedAdvisorCheck",
    "tag:GetResources",
    "tag:GetTagKeys",
    "tag:GetTagValues",
    "xray:BatchGetTraces",
    "xray:GetTraceSummaries",
    "ecs:ListClusters",
    "ecs:ListContainerInstances",
    "ecs:DescribeContainerInstances"

 ],
 "Effect": "Allow",
 "Resource": "*"
 }
 ]
}
EOF
}

resource "aws_iam_role" "dd_integration_role" {
 name = "DatadogAWSIntegrationRole"

 assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Principal": { "AWS": "arn:aws:iam::464622532012:root" },
        "Action": "sts:AssumeRole",
        "Condition": { "StringEquals": { "sts:ExternalId": "${var.shared_secret}" } }
    }
}
EOF
}

resource "aws_iam_policy_attachment" "allow_dd_role" {
 name = "Allow Datadog PolicyAccess via Role"
 roles = ["${aws_iam_role.dd_integration_role.name}"]
 policy_arn = "${aws_iam_policy.dd_integration_policy.arn}"
}

