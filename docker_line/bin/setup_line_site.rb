# LINE 連携マニュアル（settings/line/messaging.html「マイページ設定」、settings/line/service.html「Webhook」）に沿って、
# サイトに足りないフォルダーと公開ドメインを整える。再実行しても壊れない。
#   bundle exec rails runner docker_line/bin/setup_line_site.rb
#
# 環境変数:
#   SITE_HOST      対象サイトの host（既定 www）
#   PUBLIC_DOMAIN  ngrok 等の公開ドメイン（例 your-name.ngrok-free.app）。未設定なら公開ドメインの設定は行わない
site_host = ENV.fetch("SITE_HOST", "www")
public_domain = ENV["PUBLIC_DOMAIN"].to_s.strip

site = Cms::Site.find_by(host: site_host)

def ensure_node(site, klass, filename, attrs)
  node = Cms::Node.site(site).where(filename: filename).first
  if node
    puts "exists  node: #{filename} (#{node.route})"
    return node
  end

  parent = Cms::Node.site(site).where(filename: ::File.dirname(filename)).first if filename.include?("/")
  node = klass.new(attrs.merge(cur_site: site, filename: filename))
  node.layout_id ||= parent.layout_id if parent
  node.group_ids = parent.group_ids if parent && node.group_ids.blank?
  node.group_ids = SS::Group.pluck(:id) if node.group_ids.blank?
  node.save!
  puts "created node: #{filename} (#{node.route})"
  node
end

# 1. Webhook の受け口「標準機能/LINE HUB」（デモデータでは receiver として作成済み）
hub = Cms::Node::LineHub.site(site).first
hub ||= ensure_node(site, Cms::Node::LineHub, "receiver", name: "LINE HUB")

# 2. マイページ配下「メンバー/LINEプロフィール」（配信カテゴリーの購読設定画面）
ensure_node(site, Member::Node::MyLineProfile, "mypage/line-profile", name: "LINEプロフィール", order: 30)

# 3. ログインフォルダーのリダイレクト先をマイページにする（デモデータでは設定済み）
login = Member::Node::Login.site(site).first
if login && login.redirect_url.blank?
  login.redirect_url = "/mypage/"
  login.save!
  puts "updated node: #{login.filename} redirect_url=/mypage/"
end

# 4. 公開ドメイン（ngrok）。LINE からの Webhook / LINE Login のコールバックは https の公開 URL にしか届かない
if public_domain.present?
  site.domains = ([public_domain] + site.domains).uniq
  site.mypage_domain = public_domain
  site.mypage_scheme = "https"
  site.https = "enabled"
  site.save!
  puts "updated site: domains=#{site.domains.join(', ')} mypage_domain=#{site.mypage_domain} https=enabled"
end

base = public_domain.present? ? "https://#{public_domain}" : "https://<公開ドメイン>"
puts
puts "== LINE Developers コンソールに設定する URL =="
puts "Messaging API チャネル > Webhook URL:      #{base}/#{hub.filename}/line"
puts "LINE Login チャネル    > コールバック URL: #{base}/#{login ? login.filename : 'login'}/line/callback"
puts
puts "== シラサギ側で残っている設定（管理画面） =="
puts "サイト設定 > LINE設定: チャンネルシークレット / チャンネルアクセストークン"
puts "フォルダー「#{login ? login.filename : 'login'}」の編集: LINE OAuth を有効にし、LINE Login チャネルの ID / シークレットを設定"
