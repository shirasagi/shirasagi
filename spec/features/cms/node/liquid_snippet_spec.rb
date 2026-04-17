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

  it "loads selected liquid loop setting into loop_liquid without showing loading text" do
    visit edit_node_conf_path(site.id, node)

    ensure_addon_opened('#addon-event-agents-addons-page_list')

    within '#addon-event-agents-addons-page_list' do
      select('Liquid', from: 'item[loop_format]') if page.has_select?('item[loop_format]')
      wait_for_js_ready

      select_loop_setting('item_loop_setting_id_liquid', liquid_template_low.name)
      wait_for_editor_or_textarea_value('item_loop_liquid', snippet_html_low)

      expect(editor_or_textarea_value('item_loop_liquid')).to include(snippet_html_low)
      expect(loop_snippet_select).to be_disabled
      expect(page).to have_no_css('.translation_missing[title*="ss.notice.loading"]')
      expect(page).to have_no_content('translation missing: ja.ss.notice.loading')
    end
  end
end
