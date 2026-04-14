require 'spec_helper'

describe "cms loop setting propagation to folders (E2E)", type: :feature, dbscope: :example, js: true do
  let!(:site)  { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node)  { create :article_node_page, layout_id: layout.id, filename: "node" }
  let!(:item)  { create :article_page, layout_id: layout.id, filename: "node/item", name: "article-#{unique_id}" }

  let(:loop_setting_name) { "propagation-setting-#{unique_id}" }

  before { login_cms_user }

  # 初期 / 更新済み の対比がひと目で分かるよう、初期 = <p>新規作成</p>、更新後 = <p>更新済み</p> を必ず含める
  def shirasagi_html(marker)
    %(<p class="propagation-status">#{marker}</p><article class="propagation-item"><a href="\#{url}">\#{name}</a></article>)
  end

  def liquid_html(marker)
    <<~HTML.strip
      {% for page in pages %}
      <p class="propagation-status">#{marker}</p>
      <article class="propagation-item"><a href="{{ page.url }}">{{ page.name }}</a></article>
      {% endfor %}
    HTML
  end

  shared_examples "loop setting html update propagates to folder page" do
    it "reflects the edited loop HTML ('新規作成' → '更新済み') on the folder's public page" do
      #
      # 1. 管理画面でループHTMLを新規作成 — 初期: <p>新規作成</p>
      #
      visit new_cms_loop_setting_path(site.id)
      within "form#item-form" do
        fill_in "item[name]", with: loop_setting_name
        select format_label, from: "item[html_format]"
        fill_in_code_mirror "item[html]", with: body_html.call("新規作成")
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      loop_setting = Cms::LoopSetting.where(name: loop_setting_name).first
      expect(loop_setting).to be_present
      expect(loop_setting.html).to include("<p class=\"propagation-status\">新規作成</p>")
      expect(loop_setting.html).not_to include("更新済み")

      #
      # 2. 記事フォルダを編集してループ設定を紐付け
      #
      visit edit_node_conf_path(site.id, node)
      ensure_addon_opened('#addon-event-agents-addons-page_list')

      within '#addon-event-agents-addons-page_list' do
        select loop_format_label, from: 'item[loop_format]'
        wait_for_js_ready
        select loop_setting_name, from: loop_setting_select_id
        wait_for_js_ready
      end
      within 'footer.send' do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      node.reload
      expect(node.loop_setting_id).to eq loop_setting.id

      #
      # 3. 公開ページ(記事フォルダ)を表示 — 初期 <p>新規作成</p> が反映されていること
      #
      Capybara.app_host = "http://#{site.domain}"
      visit node.url
      expect(page).to have_css('.propagation-status', text: '新規作成')
      expect(page).to have_no_css('.propagation-status', text: '更新済み')

      #
      # 4. 管理画面に戻り、同じループHTMLを編集 — <p>更新済み</p> に書き換えて保存
      #
      Capybara.app_host = nil
      visit edit_cms_loop_setting_path(site.id, loop_setting)
      within "form#item-form" do
        fill_in_code_mirror "item[html]", with: body_html.call("更新済み")
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      loop_setting.reload
      expect(loop_setting.html).to include("<p class=\"propagation-status\">更新済み</p>")
      expect(loop_setting.html).not_to include("新規作成")

      #
      # 5. 公開ページを再表示 — <p>更新済み</p> に変化していること
      #
      Capybara.app_host = "http://#{site.domain}"
      visit node.url
      expect(page).to have_css('.propagation-status', text: '更新済み')
      expect(page).to have_no_css('.propagation-status', text: '新規作成')
    end
  end

  context "SHIRASAGI format template" do
    let(:format_label) { "SHIRASAGI" }
    let(:loop_format_label) { "SHIRASAGI" }
    let(:loop_setting_select_id) { 'item_loop_setting_id' }
    let(:body_html) { method(:shirasagi_html) }

    include_examples "loop setting html update propagates to folder page"
  end

  context "Liquid format template" do
    let(:format_label) { "Liquid" }
    let(:loop_format_label) { "Liquid" }
    let(:loop_setting_select_id) { 'item_loop_setting_id_liquid' }
    let(:body_html) { method(:liquid_html) }

    include_examples "loop setting html update propagates to folder page"
  end
end
