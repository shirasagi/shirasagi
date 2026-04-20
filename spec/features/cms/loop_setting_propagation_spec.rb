require 'spec_helper'

describe "cms loop setting propagation to folders (E2E)", type: :feature, dbscope: :example, js: true do
  let!(:site)  { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node)  { create :article_node_page, layout_id: layout.id, filename: "node" }
  let!(:item)  { create :article_page, layout_id: layout.id, filename: "node/item", name: "article-#{unique_id}" }

  let(:loop_setting_name) { "propagation-setting-#{unique_id}" }

  before do
    # 他テストが書き出した静的HTMLが残ると x_sendfile でそれが優先されるため、毎回掃除する
    FileUtils.rm_rf site.path
    FileUtils.mkdir_p site.path
    login_cms_user
  end

  # Capybara.app_host はグローバル状態。テスト中にサイトドメインへ切り替えるため、
  # 例外時も含めて確実に元へ戻す (他のテストへの汚染防止)。
  around do |example|
    original_app_host = Capybara.app_host
    begin
      example.run
    ensure
      Capybara.app_host = original_app_host
    end
  end

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

      visit edit_node_conf_path(site.id, node)
      within '#addon-event-agents-addons-page_list' do
        expect(page).to have_select(loop_setting_select_id, selected: loop_setting_name)
      end

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

  #
  # Cms::Form の LayoutHtml アドオンが loop_setting を参照しているケース
  # （Cms::Form#render_html が loop_setting.html を優先して使うことの検証）
  #
  context "Cms::Form layout html with loop setting" do
    let(:form_loop_setting_name) { "form-propagation-setting-#{unique_id}" }
    let(:form_html_template) do
      lambda do |marker|
        <<~HTML.strip
          <section class="propagation-form">
            <p class="propagation-status">#{marker}</p>
            {% for value in values %}<div class="propagation-value">{{ value }}</div>{% endfor %}
          </section>
        HTML
      end
    end

    let!(:loop_setting) do
      create(:cms_loop_setting, :liquid, :template_type,
             cur_site: site,
             name: form_loop_setting_name,
             html: form_html_template.call("新規作成"))
    end
    let!(:form) do
      create(:cms_form,
             cur_site: site, state: "public", sub_type: "entry",
             html: "<!-- direct html should be ignored when loop_setting is present -->",
             loop_setting_id: loop_setting.id)
    end
    let!(:column) do
      create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1)
    end
    let!(:article_node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id,
             filename: "form-node", st_form_ids: [form.id])
    end
    let!(:article_page) do
      create(:article_page,
             cur_site: site, cur_node: article_node, layout_id: layout.id,
             form: form, filename: "form-node/form-page", state: "public",
             name: "form-article-#{unique_id}",
             column_values: [
               column.value_type.new(column_id: column.id, order: 0, value: "<em>column-body</em>")
             ])
    end

    it "reflects the edited Cms::LoopSetting html ('新規作成' → '更新済み') on a form-backed page" do
      # 1. 初期状態: ループHTMLの「新規作成」が公開ページに反映されていること
      Capybara.app_host = "http://#{site.domain}"
      visit article_page.full_url
      expect(page).to have_css('.propagation-form .propagation-status', text: '新規作成')
      expect(page).to have_no_css('.propagation-form .propagation-status', text: '更新済み')

      # 2. 管理画面からループHTMLを編集
      Capybara.app_host = nil
      visit edit_cms_loop_setting_path(site.id, loop_setting)
      within "form#item-form" do
        fill_in_code_mirror "item[html]", with: form_html_template.call("更新済み")
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      loop_setting.reload
      expect(loop_setting.html).to include('<p class="propagation-status">更新済み</p>')

      # 3. ループHTMLを参照しているノード・ページを再書き出し
      #    （管理画面の「フォルダーの書き出し」「ページの書き出し」相当のジョブを実行）
      Cms::Node::GenerateJob.bind(site_id: site.id).perform_now
      Cms::Page::GenerateJob.bind(site_id: site.id).perform_now

      # 4. 公開ページを再表示すると、更新済みの内容に差し替わっている
      #    （Chrome は同一 URL の HTML レスポンスをキャッシュするため、クエリで確実に revalidate させる）
      Capybara.app_host = "http://#{site.domain}"
      visit "#{article_page.full_url}?_=#{Time.now.to_i}"
      expect(page).to have_css('.propagation-form .propagation-status', text: '更新済み')
      expect(page).to have_no_css('.propagation-form .propagation-status', text: '新規作成')
    end
  end

  #
  # 仕様: ループHTMLの「公開ステータス」は **選択UIの絞り込みのみ** で使用する。
  # 描画側 (Cms::Form#render_html / Cms::ListHelper#liquid_loop_source 等) は state を見ない。
  #
  # 理由:
  #   紐付け後に state を closed に変更すると、紐付いているすべてのフォルダ/フォーム/カラムで
  #   「記事ページが突然見えなくなる」事故につながる。state 変更だけで大量のページ表示が壊れる
  #   副作用を避けるため、描画側ではステータスを参照しない。
  #
  # このコンテキストはその仕様を回帰防止のために E2E で固定する。
  #
  context "loop_setting の公開ステータス運用 (E2E)" do
    let(:marker) { "closed-state-#{unique_id}" }
    let(:closed_loop_html) do
      <<~HTML.strip
        {% for page in pages %}
        <p class="closed-status">#{marker}</p>
        <article class="closed-item"><a href="{{ page.url }}">{{ page.name }}</a></article>
        {% endfor %}
      HTML
    end

    describe "紐付け後に loop_setting を closed に変更しても既存ページは壊れない" do
      let!(:loop_setting) do
        create(:cms_loop_setting, :liquid, :template_type,
               cur_site: site, state: 'public',
               name: "live-setting-#{unique_id}",
               html: closed_loop_html)
      end

      before do
        node.update!(loop_format: 'liquid', loop_setting_id: loop_setting.id)
      end

      it "state を closed に変更しても記事フォルダの公開ページは loop_setting.html で描画し続ける" do
        # 1. 初期状態: 公開ステータスで公開ページに反映されている
        Capybara.app_host = "http://#{site.domain}"
        visit node.url
        expect(page).to have_css('.closed-status', text: marker)

        # 2. 管理画面でループHTMLのステータスを closed に変更
        Capybara.app_host = nil
        visit edit_cms_loop_setting_path(site.id, loop_setting)
        within "form#item-form" do
          select I18n.t('ss.options.state.closed'), from: 'item[state]'
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(loop_setting.reload.state).to eq 'closed'

        # 3. 再書き出し + 公開ページを再訪問 → まだ loop_setting.html で描画される
        #    (state=closed でもレンダリングが維持されるのが仕様)
        Cms::Node::GenerateJob.bind(site_id: site.id).perform_now
        Capybara.app_host = "http://#{site.domain}"
        visit "#{node.url}?_=#{Time.now.to_i}"
        expect(page).to have_css('.closed-status', text: marker)
      end
    end

    describe "セレクト UI では公開ステータスのもののみ選択肢に出る" do
      let!(:public_template) do
        create(:cms_loop_setting, :liquid, :template_type,
               cur_site: site, state: 'public',
               name: "ui-public-template-#{unique_id}")
      end
      let!(:closed_template) do
        create(:cms_loop_setting, :liquid, :template_type,
               cur_site: site, state: 'closed',
               name: "ui-closed-template-#{unique_id}")
      end
      let!(:public_shirasagi) do
        create(:cms_loop_setting,
               cur_site: site, state: 'public', html_format: 'shirasagi',
               name: "ui-public-shirasagi-#{unique_id}")
      end
      let!(:closed_shirasagi) do
        create(:cms_loop_setting,
               cur_site: site, state: 'closed', html_format: 'shirasagi',
               name: "ui-closed-shirasagi-#{unique_id}")
      end

      def options_of(select_id)
        find("##{select_id}", visible: :all).all('option', visible: :all).map(&:text)
      end

      it "記事フォルダ編集画面では Liquid/SHIRASAGI どちらのセレクタからも closed は除外される" do
        visit edit_node_conf_path(site.id, node)
        ensure_addon_opened('#addon-event-agents-addons-page_list')

        within '#addon-event-agents-addons-page_list' do
          # SHIRASAGI 側セレクタ
          select 'SHIRASAGI', from: 'item[loop_format]'
          wait_for_js_ready
          shirasagi_options = options_of('item_loop_setting_id')
          expect(shirasagi_options).to include(public_shirasagi.name)
          expect(shirasagi_options).not_to include(closed_shirasagi.name)

          # Liquid 側セレクタ
          select 'Liquid', from: 'item[loop_format]'
          wait_for_js_ready
          liquid_options = options_of('item_loop_setting_id_liquid')
          expect(liquid_options).to include(public_template.name)
          expect(liquid_options).not_to include(closed_template.name)
        end
      end

      it "定型フォームのレイアウトHTML編集画面でも closed は除外される" do
        form = create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry')
        visit edit_cms_form_path(site.id, form)

        # レイアウトHTMLアドオンの template セレクタは Cms::Form でのみ表示される
        options = all(".loop-setting-selector option", visible: :all).map(&:text)
        expect(options).to include(public_template.name)
        expect(options).not_to include(closed_template.name)
        # SHIRASAGI は Cms::Form のレイアウトHTMLアドオンでは使わない
        expect(options).not_to include(public_shirasagi.name)
      end
    end
  end
end
