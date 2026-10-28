# docker_line — LINE 連携を試すための実験用 Docker 環境

SHIRASAGI の LINE 連携（[LINE メッセージ配信機能](https://shirasagi.github.io/settings/line/messaging.html)、
[LINE イベントフック](https://shirasagi.github.io/settings/line/service.html)、
[LINE リッチメニュー](https://shirasagi.github.io/settings/line/richmenu.html)）を、
手元の Docker で動かして確認するための一式です。

- 追加物はこのフォルダーに閉じています。不要になったらフォルダーごと削除してください（本体コードは触っていません）
- DB はコンテナ内の MongoDB に閉じるので、ホストの MongoDB や他の worktree のデータとは混ざりません
- コードはホスト側をマウントしているので、編集はそのまま反映されます（ホットリロード）

## 構成

```
  LINE プラットフォーム（Webhook / LINE Login コールバック / Messaging API）
        │ https                                   ▲ https (line-bot-api gem)
        ▼                                         │
  ┌─ tunnel (ngrok) ─┐  ※ profile: tunnel。公開 URL が要るときだけ
  └────────┬─────────┘
           ▼ :3000
  ┌─ web ──────────────────────────┐   ┌─ mongo (8.0) ─────┐
  │ ruby 3.3.9 + Node 24 + yarn    │──▶│ DB "ss"           │
  │ puma / webpack / rake job:run  │   │ volume mongo_data │
  └────────────────────────────────┘   └───────────────────┘
  ┌─ scheduler ────────────────────┐  ※ profile: scheduler。配信予約を自動実行したいときだけ
  │ cms:line:deliver を 15 分ごと   │
  │ cms:line:apply_richmenu を毎日  │
  └────────────────────────────────┘
```

| ファイル | 役割 |
|---|---|
| `Dockerfile` | web / scheduler のイメージ。Ruby 3.3.9（本番 `bin/install.sh` と同じ）＋ ImageMagick ＋ Node.js 24 / yarn |
| `docker-compose.yml` | 上図のサービス定義 |
| `mongoid.yml` | コンテナ内 mongo を向く Mongoid 設定。`/app/config/mongoid.yml` にマウントされ、ホストの `config/mongoid.yml` は変更しない |
| `bin/start.sh` | web の起動（gem / node_modules 導入 → 未ビルドならアセットビルド → puma） |
| `bin/setup.sh` | 初回セットアップ（インデックス作成、自治体サンプルサイト作成、デモデータ投入、LINE 用フォルダー整備） |
| `bin/setup_line_site.rb` | マニュアルの「マイページ設定」「Webhook」に沿ってフォルダーと公開ドメインを整える rails runner |
| `bin/scheduler.sh` | 本番 cron の代わりに配信予約とリッチメニュー更新を定期実行 |
| `ngrok.yml` | tunnel（ngrok）の設定。管理 UI を 0.0.0.0 で待ち受ける |
| `.env.example` | ngrok のトークン／ドメインなどの雛形。`.env` にコピーして使う（`.env` は git 管理外） |

LINE 連携は `line-bot-api` / `omniauth-line` gem の HTTPS 通信だけで完結し、OS コマンドを呼びません。
そのため MeCab / Open JTalk / Chrome などは入れていません（`.devcontainer` との違い）。

## 前提

- Docker Desktop（または Docker Engine + Compose v2）
- ポート 3000 / 27018 / 4040 が空いていること（確認: `lsof -nP -iTCP:3000 -sTCP:LISTEN`。別 worktree の puma が握っていると
  `www.example.jp:3000` がそちらに吸われます。`ruby` が出たら止めてください）
- `/etc/hosts` に `127.0.0.1 www.example.jp`（公開サイトをブラウザで見る場合）
- LINE 側: LINE 公式アカウント、[LINE Developers コンソール](https://developers.line.biz/console/) の
  **Messaging API チャネル** と **LINE Login チャネル**（**同じプロバイダー**配下に作ること。別プロバイダーだと userId が一致せず
  セグメント配信先に使えません）
- Webhook / LINE Login を実際に動かす場合: [ngrok](https://dashboard.ngrok.com/) のアカウント（無料枠の固定ドメイン 1 つで足ります）

## 起動手順

リポジトリのルートで実行します。

```bash
# 1. （任意）ngrok を使うなら .env を用意
cp docker_line/.env.example docker_line/.env   # NGROK_AUTHTOKEN / NGROK_DOMAIN を記入

# 2. イメージをビルドして mongo / web を起動（初回は gem / node_modules の導入とアセットビルドで数分かかります）
docker compose -f docker_line/docker-compose.yml up --build -d

# 3. 初回のみ: インデックス作成・サンプルサイト作成・デモデータ投入・LINE 用フォルダー整備
docker compose -f docker_line/docker-compose.yml run --rm web bash docker_line/bin/setup.sh

# 4. ログを見る / 止める
docker compose -f docker_line/docker-compose.yml logs -f web
docker compose -f docker_line/docker-compose.yml down        # データは残る
```

- 管理画面: <http://localhost:3000/.mypage>（admin / pass）
- 公開サイト: <http://www.example.jp:3000/>
- `setup.sh` は再実行しても壊れません（サイトがあればシードを飛ばし、フォルダーは無いものだけ作ります）
- `setup.sh` の最後に、LINE Developers に設定する **Webhook URL** と **コールバック URL** が表示されます

デモデータには LINE 連携の確認に必要な次のものが入っています。

| 種類 | 内容 |
|---|---|
| フォルダー | `receiver`（標準機能/LINE HUB = Webhook 受け口）、`login`（メンバー/ログイン）、`mypage`（メンバー/マイページ） |
| `setup_line_site.rb` が追加 | `mypage/line-profile`（メンバー/LINEプロフィール = 配信カテゴリーの購読設定画面） |
| LINE メニュー | 配信カテゴリー（年代・性別・住居地域）、配信条件、メッセージ雛形 |

## LINE 側の設定

### 1. Messaging API チャネル → サイト設定

[マニュアル](https://shirasagi.github.io/settings/line/messaging.html#line-messaging-api)どおり、
管理画面「サイト設定 ＞ LINE設定」に次を入力します。

| LINE Developers | シラサギ（サイト設定 ＞ LINE設定） |
|---|---|
| チャネル基本設定 ＞ チャネルシークレット | チャンネルシークレット |
| Messaging API設定 ＞ チャネルアクセストークン（長期） | チャンネルアクセストークン |

Webhook を使う（トーク返信・イベントフック）場合は、Messaging API 設定の **Webhook URL** に
`https://<公開ドメイン>/receiver/line` を設定し、「Webhook の利用」をオンにします（`receiver` は LINE HUB フォルダー名）。

### 2. LINE Login チャネル → ログインフォルダー

1. LINE Login チャネルの **コールバック URL** に `https://<公開ドメイン>/login/line/callback` を設定
2. 管理画面でフォルダー `login`（メンバー/ログイン）を編集し、**LINE OAuth を「有効」**にして、
   LINE Login チャネルの **チャネル ID / チャネルシークレット** を入力（[OAuth 認証](https://shirasagi.github.io/settings/oauth.html)）
3. リダイレクト URL は `/mypage/` になっています（デモデータの既定）

### 3. 公開ドメイン（ngrok）

LINE からの Webhook とログインのコールバックは **https の公開 URL** にしか届きません（マニュアル「制限」）。
`.env` に `NGROK_AUTHTOKEN` と `NGROK_DOMAIN` を書いて、`tunnel` profile を付けて起動します。

```bash
docker compose -f docker_line/docker-compose.yml --profile tunnel up -d
docker compose -f docker_line/docker-compose.yml run --rm web bash docker_line/bin/setup.sh   # ドメインをサイトに反映
```

`setup.sh`（`setup_line_site.rb`）は `NGROK_DOMAIN` を見て、サイトの **ドメインの先頭に追加**し、
**マイページドメインも同じ値**にし、**SSL 設定を有効**にします。
これにより LINE に渡す絶対 URL（イメージマップ画像、ログイン後のマイページ等）が公開ドメインになります。
`www.example.jp:3000` もドメインに残るので、ローカルからの閲覧はそのまま可能です。
ngrok の受信状況は <http://localhost:4040> で確認できます。

> ngrok を使わない場合でも、管理画面での LINE メッセージ作成・テスト配信（LINE メニュー ＞ テストメンバーに
> LINE の userId を登録 → メッセージを「テスト配信」）は動きます。Webhook とメンバーログインだけが公開 URL を必要とします。

## 配信予約・リッチメニュー更新（scheduler）

本番では cron（[定期実行](https://shirasagi.github.io/settings/cron.html)）で `cms:line:deliver` を 15 分ごと、
`cms:line:apply_richmenu` を毎日動かします。この環境では `scheduler` profile がその代わりをします。

```bash
docker compose -f docker_line/docker-compose.yml --profile scheduler up -d
# 手で 1 回だけ実行したいとき
docker compose -f docker_line/docker-compose.yml exec web bundle exec rake cms:line:deliver site=www
docker compose -f docker_line/docker-compose.yml exec web bundle exec rake cms:line:apply_richmenu site=www
```

間隔は `.env` の `LINE_DELIVER_INTERVAL`（秒、既定 900）で変えられます。

## 非同期ジョブ（即時配信・テスト配信）

即時配信やテスト配信は ActiveJob（`queue_adapter = :shirasagi`）で動きます。
development の既定は `on_demand` モードで、ジョブが登録されると web コンテナ内で `rake job:run` が自動起動するため、
追加のワーカーコンテナは不要です。実行結果は管理画面「LINE ＞ 配信ログ」と `log/development.log` で確認できます。

## 動作確認の流れ（例）

1. `setup.sh` 完了後、管理画面にログインし「サイト設定 ＞ LINE設定」にチャネルシークレット／アクセストークンを入力
2. 「LINE ＞ テストメンバー」に自分の LINE userId を登録（Messaging API チャネルの「あなたのユーザーID」）
3. 「LINE ＞ メッセージ」で作成し、**テスト配信** → 自分の LINE に届くこと
4. （ngrok あり）スマホで `https://<公開ドメイン>/login/` から LINE ログイン → マイページの「LINEプロフィール」で配信カテゴリーを購読
5. 「LINE ＞ メッセージ」で配信条件を付けて配信 → 購読者に届くこと（セグメント配信）
6. （ngrok あり）トークに発言 → LINE HUB 経由で「LINE ＞ サービス」のイベントフックが応答すること

## よくあるハマりどころ

- **別のサーバーに繋がる／編集が反映されない**: ホストの別 puma が `:3000` を握っている。`lsof -nP -iTCP:3000 -sTCP:LISTEN` で確認
- **404 / サイトが見つからない**: SHIRASAGI は Host ヘッダーでサイトを選びます。`localhost:3000` は管理画面用、公開サイトは
  `www.example.jp:3000`（`/etc/hosts`）か、サイトのドメインに登録した公開ドメインでアクセスしてください
- **Webhook 検証が失敗する**: LINE HUB フォルダーが公開状態か、サイト設定のチャネルシークレットが Messaging API チャネルのものか、
  ngrok の URL とサイトのドメイン（`setup.sh` 実行済みか）を確認。ngrok の <http://localhost:4040> で届いたリクエストを見られます
- **LINE ログイン後にエラー**: コールバック URL（`/login/line/callback`）と、ログインフォルダーに入れた ID / シークレットが
  **LINE Login チャネル**のもの（Messaging API のものではない）かを確認
- **ログインできない（パスワード不一致）**: パスワードの暗号化ソルトは `tmp/local_secret.txt` です。`tmp/` を消すと全パスワードが
  検証不能になります。消した場合は `down -v` で DB も作り直してください
- **JS / CSS が崩れる**: `docker compose -f docker_line/docker-compose.yml exec web yarn build`
- **ベースイメージを変えた**: gem のネイティブ拡張が合わなくなるので `docker volume rm shirasagi-line_bundle shirasagi-line_node_modules`
  してから `up --build`（`mongo_data` は残してよい）

## 後片付け

```bash
docker compose -f docker_line/docker-compose.yml down       # コンテナ停止。DB / gem / node_modules は volume に残る
docker compose -f docker_line/docker-compose.yml down -v    # volume も削除（DB のデータが消える）
rm -rf docker_line                                           # この環境ごと撤去（本体コードへの変更は無い）
```

`setup_line_site.rb` で公開ドメインを設定した場合、サイトのドメイン／SSL 設定は DB に残ります。
ngrok をやめるときは管理画面「サイト設定 ＞ 基本設定」で元に戻すか、`down -v` で作り直してください。
