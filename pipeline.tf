# CodeBuild用のロール
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

# CodeBuildに必要な権限（ECRへのプッシュやログ出力など）
resource "aws_iam_role_policy_attachment" "codebuild_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # 本来は絞るべきですが、まずは疎通優先で
}

resource "aws_codebuild_project" "tabelog_build" {
  name         = "tabelog-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "ARM_CONTAINER"

    environment_variable {
      name  = "CONTAINER_NAME"
      type  = "PLAINTEXT"
      value = "tabelog-container"
    }
    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      type  = "PLAINTEXT"
      value = "tabelog-cluster"
    }
    environment_variable {
      name  = "ECS_SERVICE_NAME"
      type  = "PLAINTEXT"
      value = "tabelog-service"
    }
    environment_variable {
      name  = "MIGRATION_TASK_DEFINITION"
      type  = "PLAINTEXT"
      value = "tabelog-task"
    }
    environment_variable {
      name  = "REPOSITORY_URI"
      type  = "PLAINTEXT"
      value = "163053485036.dkr.ecr.ap-northeast-1.amazonaws.com/tabelog-repo"
    }
    environment_variable {
  name  = "security_group_ID"
      type  = "PLAINTEXT"
      value = "sg-0e4c6830c5800979d"
    }
    environment_variable {
      name  = "security_group_IDS"
      type  = "PLAINTEXT"
      value = "sg-09a44710089c96f43"
    }
    environment_variable {
      name  = "SSM_ENV"
      type  = "PLAINTEXT"
      value = "dev"
    }
    environment_variable {
      name  = "SUBNET_ID_1"
      type  = "PLAINTEXT"
      value = "subnet-0b54f426254309417"
    }
    environment_variable {
      name  = "SUBNET_ID_2"
      type  = "PLAINTEXT"
      value = "subnet-07ba752e84adb8baa"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}


resource "aws_codepipeline" "tabelog_pipeline" {
  name     = "tabelog-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn # ※別途Pipeline用のRole作成が必要

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket # ※別途S3バケットが必要
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = "arn:aws:codeconnections:ap-northeast-1:163053485036:connection/70224714-2992-4893-a7ae-f3b656b7f9af" #事前にCodeStar Connectionsで作成した接続のARNを指定
        FullRepositoryId = "hiroki-bui/Nagoyameshi"                                                                              #修正
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.tabelog_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ClusterName = "tabelog-cluster"
        ServiceName = "tabelog-service"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
# CodePipeline用のロール
resource "aws_iam_role" "pipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_attach" {
  role       = aws_iam_role.pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # 疎通確認のため
}
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "tabelog-pipeline-artifacts-163053485036" # 名前が重複しないようアカウントID等を付けるのがおすすめ
}
