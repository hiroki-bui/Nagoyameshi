# CodeBuild用のロール
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
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
  name          = "tabelog-build"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Dockerビルドに必須

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "163053485036" # AWSアカウントIDを指定
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "tabelog-repo" # ECRのリポジトリ名
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "tabelog-container" # task-definition.jsonのcontainerDefinitionsの名前
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
        ConnectionArn    = "arn:aws:codeconnections:ap-northeast-1:163053485036:connection/70224714-2992-4893-a7ae-f3b656b7f9af"  #事前にCodeStar Connectionsで作成した接続のARNを指定
        FullRepositoryId = "hiroki-bui/Nagoyameshi" #修正
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
      Action = "sts:AssumeRole"
      Effect = "Allow"
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
