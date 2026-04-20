require 'spec_helper'

describe "cms node liquid snippets", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create(:article_node_page, cur_site: site) }
  let(:snippet_html_high) { "{% for item in items %}<div class='snippet-high'>{{ item.name }}</div>{% endfor %}" }
  let(:snippet_html_low) { "{% for item in items %}<div class='snippet-low'>{{ item.title }}</div>{% endfor %}" }

  let!(:liquid_setting_high) do
    create(:cms_loop_setting, :liquid, :snippet_type,
      site: site,
      state: "public",
      order: 20,
      name: "Liquid Snippet High",
      html: snippet_html_high)
  end

  let!(:liquid_setting_low) do
    create(:cms_loop_setting, :liquid, :snippet_type,
      site: site,
      state: "public",
      order: 5,
      name: "Liquid Snippet Low",
      html: snippet_html_low)
  end

  let!(:liquid_setting_closed) do
    create(:cms_loop_setting, :liquid, :snippet_type,
      site: site,
      state: "closed",
      name: "Liquid Snippet Closed")
  end

  let!(:liquid_template_low) do
    create(:cms_loop_setting, :liquid, :template_type,
      site: site,
      state: "public",
      order: 5,
      name: "Liquid Template Low",
      html: snippet_html_low)
  end

  before do
    login_cms_user
  end

  def loop_snippet_select
    find('.loop-snippet-selector', visible: :all)
  end

  def select_loop_snippet(option_text)
    select option_text, from: loop_snippet_select[:id]
  end

  def select_loop_setting(select_id, option_text)
    select option_text, from: select_id
  end

  def editor_or_textarea_value(field_id)
    page.evaluate_script(<<~JS)
      (function() {
        var el = document.getElementById("#{field_id}");
        if (!el) { return null; }

        var editor = $(el).data("editor");
        if (editor && typeof editor.getValue === "function") {
          return editor.getValue();
        }

        return el.value;
      })();
    JS
  end

  def wait_for_editor_or_textarea_value(field_id, expected_substring, timeout: Capybara.default_max_wait_time)
    Selenium::WebDriver::Wait.new(timeout: timeout).until do
      editor_or_textarea_value(field_id).to_s.include?(expected_substring)
    end
  end

  it "inserts public liquid snippets into loop_liquid while excluding closed snippets" do
    visit edit_node_conf_path(site.id, node)

    ensure_addon_opened('#addon-event-agents-addons-page_list')

    within '#addon-event-agents-addons-page_list' do
      select('Liquid', from: 'item[loop_format]') if page.has_select?('item[loop_format]')
      wait_for_js_ready

      expect(page).to have_css('.loop-snippet-selector', wait: 5)

      option_texts = loop_snippet_select.all('option').map(&:text)

      expect(option_texts).to include(liquid_setting_high.name)
      expect(option_texts).to include(liquid_setting_low.name)
      expect(option_texts).not_to include(liquid_setting_closed.name)

      liquid_names = option_texts.reject(&:blank?)
      expect(liquid_names.index(liquid_setting_low.name)).to be < liquid_names.index(liquid_setting_high.name)

      fill_in_code_mirror 'item[loop_liquid]', with: "existing-liquid-content"

      select_loop_snippet(liquid_setting_high.name)

      expect(loop_snippet_select.value).to eq ""

      textarea_value = find('#item_loop_liquid', visible: false).value
      expect(textarea_value).to include("existing-liquid-content")
      expect(textarea_value).to include(snippet_html_high)
    end
  end

  #
  # page_list _form.html.erb には `name="item[loop_setting_id]"` を持つ select が
  # SHIRASAGI 側と Liquid 側で **2つ** 並んで描画されている。
  # 同じ name の form control は disabled だと送信されないという HTML 仕様を利用し、
  # loop_format に応じて片方を disabled にすることで、実際に送信される値を切り替えている。
  #
  # このため、形式を切り替えて保存したとき、非活性側に残っていた loop_setting_id は
  # そもそも送信されず、DB に前の形式の値が残ることがない。
  # この disabled toggle が壊れるとデータ整合性が崩れるため、回帰防止としてテストする。
  #
  it "disables the opposite loop_setting_id selector based on loop_format" do
    visit edit_node_conf_path(site.id, node)
    ensure_addon_opened('#addon-event-agents-addons-page_list')

    within '#addon-event-agents-addons-page_list' do
      select 'SHIRASAGI', from: 'item[loop_format]'
      wait_for_js_ready
      expect(find('#item_loop_setting_id', visible: :all)).not_to be_disabled
      expect(find('#item_loop_setting_id_liquid', visible: :all)).to be_disabled

      select 'Liquid', from: 'item[loop_format]'
      wait_for_js_ready
      expect(find('#item_loop_setting_id', visible: :all)).to be_disabled
      expect(find('#item_loop_setting_id_liquid', visible: :all)).not_to be_disabled
    end
  end

  #
  # page_list _show.html.erb は、紐付いた loop_setting の name を表示する。
  # (管理者が一覧/詳細を見たときに「どのループHTML設定を使っているか」が一目で分かるように)
  #
  context "page_list _show.html.erb on node_conf_path" do
    let!(:shirasagi_loop_setting) do
      create(:cms_loop_setting, :shirasagi, :template_type,
             cur_site: site, state: 'public',
             name: "Shirasagi Setting #{unique_id}")
    end
    let!(:liquid_loop_setting) do
      create(:cms_loop_setting, :liquid, :template_type,
             cur_site: site, state: 'public',
             name: "Liquid Setting #{unique_id}",
             html: "{% for page in pages %}<p>{{ page.name }}</p>{% endfor %}")
    end

    it "displays the linked loop_setting name (SHIRASAGI format)" do
      node.update!(loop_format: 'shirasagi', loop_setting_id: shirasagi_loop_setting.id)
      visit node_conf_path(site.id, node)
      expect(page).to have_content(shirasagi_loop_setting.name)
    end

    it "displays the linked loop_setting name (Liquid format)" do
      node.update!(loop_format: 'liquid', loop_setting_id: liquid_loop_setting.id)
      visit node_conf_path(site.id, node)
      expect(page).to have_content(liquid_loop_setting.name)
    end

    it "does not display any loop_setting name when none is linked" do
      node.update!(loop_format: 'liquid', loop_setting_id: nil)
      visit node_conf_path(site.id, node)
      expect(page).to have_no_content(shirasagi_loop_setting.name)
      expect(page).to have_no_content(liquid_loop_setting.name)
    end
  end

  #
  # 旧仕様 (AJAX で template 内容をエディタに流し込む) は撤去済み。
  # 現在は lock 方式: テンプレート選択でエディタを readOnly にし、
  # 実際のレンダリング時に Cms::ListHelper#liquid_loop_source が loop_setting.html を適用する。
  #
  it "toggles loop_liquid editor readOnly when a liquid template is selected or cleared" do
    visit edit_node_conf_path(site.id, node)

    ensure_addon_opened('#addon-event-agents-addons-page_list')

    loop_liquid_readonly = ->do
      page.evaluate_script(<<~JS)
        (function() {
          var ta = document.getElementById('item_loop_liquid');
          var wrapper = ta && $(ta).next('.CodeMirror')[0];
          return !!(wrapper && wrapper.CodeMirror && wrapper.CodeMirror.getOption('readOnly'));
        })();
      JS
    end

    within '#addon-event-agents-addons-page_list' do
      select('Liquid', from: 'item[loop_format]') if page.has_select?('item[loop_format]')
      wait_for_js_ready

      expect(loop_liquid_readonly.call).to eq false

      # template 選択 → readOnly
      select_loop_setting('item_loop_setting_id_liquid', liquid_template_low.name)
      Selenium::WebDriver::Wait.new(timeout: Capybara.default_max_wait_time).until { loop_liquid_readonly.call }
      expect(loop_liquid_readonly.call).to eq true

      # 直接入力に戻す → 編集可能
      select_loop_setting('item_loop_setting_id_liquid', I18n.t('cms.input_directly'))
      Selenium::WebDriver::Wait.new(timeout: Capybara.default_max_wait_time).until { !loop_liquid_readonly.call }
      expect(loop_liquid_readonly.call).to eq false

      # i18n 未定義プレースホルダは出ない (回帰防止)
      expect(page).to have_no_css('.translation_missing[title*="ss.notice.loading"]')
      expect(page).to have_no_content('translation missing: ja.ss.notice.loading')
    end
  end
end
