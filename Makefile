.PHONY: help init build up down shell clean update-deps

# デフォルトターゲット
help:
	@echo "使用可能なコマンド:"
	@echo "  make init        - 初期セットアップ（uv.lockファイルの生成）"
	@echo "  make build       - Dockerイメージのビルド"
	@echo "  make up          - コンテナの起動"
	@echo "  make down        - コンテナの停止"
	@echo "  make shell       - コンテナ内でシェルを起動"
	@echo "  make clean       - コンテナとイメージの削除"
	@echo "  make update-deps - 依存関係の更新（pyproject.toml変更後）"

# 初期セットアップ（初回のみ実行）
init:
	@echo "初期セットアップを開始します..."
	@if [ ! -f app/uv.lock ]; then \
		echo "uv.lockファイルが存在しません。生成します..."; \
		docker compose build; \
		echo "uv.lockファイルを生成しています..."; \
		docker compose run --rm --entrypoint "sh" dev -c "cd /workspace/app && uv lock"; \
		echo "初期セットアップが完了しました。"; \
	else \
		echo "uv.lockファイルが既に存在します。"; \
	fi

# Dockerイメージのビルド
build:
	docker compose build

# コンテナの起動
up:
	docker compose up -d

# コンテナの停止
down:
	docker compose down

# コンテナ内でシェルを起動
shell:
	docker compose exec dev bash

# クリーンアップ
clean:
	docker compose down -v
	docker compose rm -f

# 依存関係の更新（pyproject.toml変更後）
update-deps:
	@echo "依存関係を更新しています..."
	@docker compose run --rm --entrypoint "sh" dev -c "cd /workspace/app && uv lock --upgrade"
	@echo "uv.lockファイルが更新されました。"
