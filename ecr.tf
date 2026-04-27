# ECRリポジトリの作成
resource "aws_ecr_repository" "main" {
  name                 = "tabelog-repo" # リポジトリ名
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true # イメージをプッシュした時に脆弱性診断を自動実行
  }
}

# ライフサイクルポリシー（イメージが増えすぎないように設定）
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "最新の3個だけ残して古いイメージを削除する",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 3
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# 作成したリポジトリのURLを出力（後でDockerプッシュ時に使います）
output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}