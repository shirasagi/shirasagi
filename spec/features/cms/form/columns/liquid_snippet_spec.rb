require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let(:snippet_html_primary) { "{% for item in items %}<div class='column-snippet-primary'>{{ item.name }}</div>{% endfor %}" }
  let(:snippet_html_secondary) do
    "{% for item in items %}<div class='column-snippet-secondary'>{{ item.title }}</div>{% endfor %}"
  end

  let!(:liquid_setting_primary) do
    create(:cms_loop_setting, :liquid, :snippet_type,
      site: site,
      state: 'public',
      order: 30,
      name: 'Column Snippet Primary',
      html: snippet_html_primary)
  end

  let!(:liquid_setting_secondary) do
    create(:cms_loop_setting, :liquid, :snippet_type,
      site: site,
      state: 'public',
      order: 10,
      name: 'Column Snippet Secondary',
      html: snippet_html_secondary)
  end

  let!(:liquid_setting_closed) do
    create(:cms_loop_setting, :liquid, :snippet_type,
      site: site,
      state: 'closed',
      name: 'Column Snippet Closed')
  end

  let!(:liquid_template_primary) do
    create(:cms_loop_setting, :liquid, :template_type,
      site: site,
      state: 'public',
      order: 30,
      name: 'Column Template Primary',
      html: snippet_html_primary)
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

  def editor_or_textarea_value(field_id)
    page.evaluate_script(<<~JS)
      (function() {
        var el = document.getElementById("#{field_id}");
        if (!el) { return null; }

        var editor = $(el).data('editor');
        if (editor && typeof editor.getValue === 'function') {
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

  it 'allows inserting liquid snippets into column layout field' do
    visit cms_form_path(site, form)

    click_on I18n.t('cms.buttons.manage_columns')

    within '.gws-column-list-toolbar[data-placement="top"]' do
      wait_for_event_fired('gws:column:added') { click_on I18n.t('cms.columns.cms/free') }
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within '.gws-column-form' do
      fill_in 'item[name]', with: 'Test Column'
      click_on I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

    within_dialog do
      expect(page).to have_css('.loop-snippet-selector', wait: 10)

      option_texts = loop_snippet_select.all('option').map(&:text)
      expect(option_texts).to include(liquid_setting_primary.name)
      expect(option_texts).to include(liquid_setting_secondary.name)
      expect(option_texts).not_to include(liquid_setting_closed.name)

      ordered_names = option_texts.reject(&:blank?)
      expect(ordered_names.index(liquid_setting_secondary.name)).to be < ordered_names.index(liquid_setting_primary.name)

      fill_in_code_mirror 'item[layout]', with: 'existing-column-layout'

      textarea = find('#item_layout', visible: false)
      page.execute_script("$(arguments[0]).data('editor')?.save()", textarea)
      wait_for_js_ready

      select_loop_snippet(liquid_setting_secondary.name)
      wait_for_editor_or_textarea_value('item_layout', 'column-snippet-secondary')

      value = editor_or_textarea_value('item_layout')
      expect(value).to include('existing-column-layout')
      expect(value).to include(snippet_html_secondary)
    end
  end

  #
  # フォームの「レイアウトHTML」(Cms::Form) と同じく、カラムの「レイアウト」欄も
  # テンプレート選択中は CodeMirror を readOnly に切り替える (内容は保持)。
  # 実際のレンダリング時に Cms::Column::Value::Base#_to_html が loop_setting.html を適用する。
  #
  it 'toggles column layout editor readOnly when a template is selected or cleared' do
    visit cms_form_path(site, form)

    click_on I18n.t('cms.buttons.manage_columns')

    within '.gws-column-list-toolbar[data-placement="top"]' do
      wait_for_event_fired('gws:column:added') { click_on I18n.t('cms.columns.cms/free') }
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within '.gws-column-form' do
      fill_in 'item[name]', with: 'Readonly Toggle Column'
      click_on I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

    layout_editor_readonly = -> do
      page.evaluate_script(<<~JS)
        (function() {
          var ta = document.getElementById('item_layout');
          var wrapper = ta && $(ta).next('.CodeMirror')[0];
          return !!(wrapper && wrapper.CodeMirror && wrapper.CodeMirror.getOption('readOnly'));
        })();
      JS
    end

    within_dialog do
      expect(page).to have_css('.loop-setting-selector', wait: 10)
      loop_setting_select = find('.loop-setting-selector', visible: :all)

      expect(layout_editor_readonly.call).to eq false

      select liquid_template_primary.name, from: loop_setting_select[:id]
      Selenium::WebDriver::Wait.new(timeout: Capybara.default_max_wait_time).until { layout_editor_readonly.call }
      expect(layout_editor_readonly.call).to eq true

      select I18n.t('cms.input_directly'), from: loop_setting_select[:id]
      Selenium::WebDriver::Wait.new(timeout: Capybara.default_max_wait_time).until { !layout_editor_readonly.call }
      expect(layout_editor_readonly.call).to eq false

      # i18n 未定義プレースホルダは出ない (回帰防止)
      expect(page).to have_no_css('.translation_missing[title*="ss.notice.loading"]')
      expect(page).to have_no_content('translation missing: ja.ss.notice.loading')
    end
  end
end
