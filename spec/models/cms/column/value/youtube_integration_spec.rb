require 'spec_helper'
require 'nokogiri'
require 'webmock/rspec'

describe "cms/page/youtube", type: :feature, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
  let!(:selectable_page1) { create :article_page, cur_site: site, cur_node: node, state: "public" }
  let!(:column_youtube) { create(:cms_column_youtube, cur_form: form, required: "optional", order: 1) }
  let(:youtube_url) { "https://www.youtube.com/watch?v=CSlLndeDc48" }
  let(:youtube_title) { "テスト動画タイトル" }

  before do
    # oEmbed APIのレスポンスをモック
    stub_request(:get, "https://www.youtube.com/oembed?format=json&url=#{youtube_url}")
      .to_return(
        status: 200,
        body: { title: youtube_title }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    login_cms_user
  end

  it "YouTube埋め込みiframeにtitle属性が含まれていること" do
    # 記事作成画面へ
    visit article_page_path(site: site, cid: node)

    # タイトル入力
    fill_in 'item[name]', with: 'YouTube埋め込みテスト'

    # YouTubeカラムのURL入力
    within "#addon-cms-agents-addons-column" do
      fill_in "item[column_values][][in_wrap][url]", with: youtube_url
    end

    # 公開保存ボタンをクリック
    click_on I18n.t('ss.buttons.publish_save')

    # 成功メッセージを確認
    expect(page).to have_content(I18n.t('ss.notice.saved'))

    # 公開サイトのURLを取得
    page_url = find('a', text: I18n.t('ss.links.public_view'))[:href]

    # 公開サイトを開く
    visit page_url
    html = page.html
    doc = Nokogiri::HTML.parse(html)

    # iframe要素を取得しtitle属性を確認
    iframe = doc.at_css('iframe')
    expect(iframe).to be_present
    expect(iframe['title']).to eq(youtube_title)
  end
end
