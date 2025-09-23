#!/bin/bash
# CI実行用のスクリプト
# GitHub Actionsで実行される際のエントリーポイント

set -e

# 環境変数の確認
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    exit 1
fi

if [ -z "$PR_NUMBER" ]; then
    echo "Error: PR_NUMBER environment variable is required"
    exit 1
fi

# デフォルト値の設定
TARGET_REPO=${TARGET_REPO:-"shirasagi/shirasagi"}
VERBOSE=${VERBOSE:-"false"}
CONFIG_FILE=${CONFIG_FILE:-"config.yaml"}

echo "=== CI Spec Generator ==="
echo "PR Number: $PR_NUMBER"
echo "Target Repository: $TARGET_REPO"
echo "Config File: $CONFIG_FILE"
echo "Verbose: $VERBOSE"
echo "========================="

# リポジトリ情報を抽出
REPO_OWNER=$(echo $TARGET_REPO | cut -d'/' -f1)
REPO_NAME=$(echo $TARGET_REPO | cut -d'/' -f2)

echo "Repository Owner: $REPO_OWNER"
echo "Repository Name: $REPO_NAME"

# config.yamlを更新
echo "Updating configuration..."
python3 -c "
import yaml
import os

with open('$CONFIG_FILE', 'r', encoding='utf-8') as f:
    config = yaml.safe_load(f)

config['github']['repository']['owner'] = '$REPO_OWNER'
config['github']['repository']['name'] = '$REPO_NAME'

with open('$CONFIG_FILE', 'w', encoding='utf-8') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True)

print('Configuration updated successfully')
"

# アプリケーションの実行
echo "Running CI Spec Generator..."
if [ "$VERBOSE" = "true" ]; then
    python3 main.py --pr-number $PR_NUMBER --config $CONFIG_FILE --verbose
else
    python3 main.py --pr-number $PR_NUMBER --config $CONFIG_FILE
fi

# 結果の確認
if [ -f "spec_list.txt" ]; then
    echo "=== Results ==="
    echo "spec_list.txt created successfully"
    echo "File contents:"
    cat spec_list.txt
    echo "==============="
else
    echo "Warning: spec_list.txt was not created"
    exit 1
fi

echo "CI Spec Generator completed successfully"
