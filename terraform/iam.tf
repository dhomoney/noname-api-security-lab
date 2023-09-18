# Create aws prevention policy
resource "aws_iam_policy" "aws_prevention" {
  name = "nnw-${var.customer_name}-pp"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Sid      = "WorkshopPrevention"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "wafv2:GetIPSet",
          "wafv2:GetRuleGroup",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:ListIPSets",
          "wafv2:ListResourcesForWebACL",
          "wafv2:ListRuleGroups",
          "wafv2:ListWebACLs",
          "wafv2:UpdateIPSet",
          "wafv2:UpdateRuleGroup",
          "wafv2:CheckCapacity"
        ]
      }]
  })
}

# Create EC2 role policy
resource "aws_iam_policy" "ec2_policy" {
  name = "nnw-${var.customer_name}-ec2p"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WorkshopPosture"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "autoscaling:Describe*",
          "route53:Get*",
          "route53:List*",
          "route53:TestDNSAnswer",
          "sts:DecodeAuthorizationMessage",
          "lambda:ListFunctions",
          "ec2:Describe*",
          "elasticloadbalancing:Describe*",
          "iam:ListAccountAliases"
        ]
      },
      {
        Sid      = "S3AccessShares"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::noname-workshop-share/*"
        Action = [
          "s3:GetObject"
        ]
      },
      {
        Sid      = "S3AccessPackages"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::noname-packages/*"
        Action = [
          "s3:GetObject"
        ]
      },
      {
        Sid      = "AssumePreventionRole"
        Effect   = "Allow"
        Resource = aws_iam_role.aws_prevention.arn
        Action = [
          "sts:AssumeRole"
        ]
      }]
  })
}

# Create prevention IAM Role
resource "aws_iam_role" "aws_prevention" {
  name = "nnw-${var.customer_name}-pr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AssumePostureRole"
        Principal = {
          AWS = "827217488266"
        }
      },
    ]
  })
}

# Create role to assume role
resource "aws_iam_role" "ec2_role" {
  name = "nnw-${var.customer_name}-ec2r"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AssumePostureRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach prevention policy
resource "aws_iam_role_policy_attachment" "prevention-attach" {
  role       = aws_iam_role.aws_prevention.name
  policy_arn = aws_iam_policy.aws_prevention.arn
}

# Attach ec2 policy
resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "noname_server_profile" {
  name = "nnw-${var.customer_name}-ep"
  role = aws_iam_role.ec2_role.name
}
