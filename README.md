# Laravel Nagoyameshi アプリケーション

このリポジトリは、Terraformで構築されたAWSインフラ（ECS Fargate, ALB, RDS など）にデプロイされる Laravel アプリケーションです。

---

## 🚀 デプロイ方法（Terraform連携）

このプロジェクトは、Terraform構成で作成される CodePipeline により、自動的にデプロイすることを想定しています。

---

### ✅ 必須手順（Terraform側）

Terraformプロジェクト側の `terraform.tfvars` に、このLaravel アプリケーションを管理するリポジトリの情報を記入してください：

```hcl
github_owner       = "your-github-username"
github_repo        = "your-repository-name"
github_oauth_token = "your-token"
github_branch      = "main"
```

Terraform を init → plan → apply で実行した際に、AWS CodePipeline が作成され、
このリポジトリが自動的にデプロイ対象として取り込まれるように設定してください。

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## 🐳 ローカル環境での動作確認

ローカルでの動作確認は以下の手順で行います。

### 1. .env ファイルの作成

```bash
cp laravel-nagoyameshi/.env.example laravel-nagoyameshi/.env
```

APP_KEY、DB接続情報は `.env.example` にあらかじめ記述されています。

```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel_nagoyameshi
DB_USERNAME=laravel
DB_PASSWORD=password
```

### 2. コンテナの起動

```bash
docker compose up --build
```

### 3. マイグレーションの実行

```bash
docker compose exec laravel php artisan migrate
```

### 4. ストレージのシンボリックリンク作成

画像を表示するために、初回のみ以下を実行してください：

```bash
docker compose exec laravel php artisan storage:link
```

> ⚠️ `storage:link` はローカル環境での初回セットアップ時のみ必要です。
> 本番環境（ECS Fargate）では Dockerfile.deployment のビルド時に自動実行されます。

---

## 🚀 AWS本番デプロイ用のビルドについて

AWS ECS Fargate への本番デプロイでは、以下のDockerfileを使用します：

```
Dockerfile.deployment
```

この `Dockerfile.deployment` を CodeBuild で使用し、
ECR イメージのビルド → ECS による Laravel アプリの本番環境起動が行われるように設定してください。

### マイグレーションの自動実行について

本番環境では、`buildspec.yml` の設定により、CodePipeline の Build ステージ（CodeBuild）において、
ECR へのイメージ push 後に ECS RunTask によりマイグレーションが自動実行されます。

```
GitHub push
  → CodePipeline
    → CodeBuild: Dockerイメージビルド → ECR push → migration自動実行
    → ECS Fargate: 新しいイメージでサービス更新
```

手動でのマイグレーション実行は不要です。

---

## 📦 プロジェクト構成

- Laravel 10.x
- MySQL（Amazon RDS）
- SSM Parameter Store による環境変数管理（本番環境では `.env` 不要）
- デプロイは GitHub → CodePipeline → CodeBuild → ECR → ECS の流れ

---

## 📝 注意事項

- 本番環境では `.env` は使用せず、SSM Parameter Store によって環境変数を注入してください
- ブランチ名は `terraform.tfvars` で指定した `github_branch` に合わせてください
- `push → CodePipeline → デプロイ` の自動化を前提としています