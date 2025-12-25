require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let(:snippet_html_primary) { "{% for item in items %}<div class='column-snippet-primary'>{{ item.name }}</div>{% endfor %}" }
  let(:snippet_html_secondary) do
    "{% for item in items %}<div class='column-snippet-secondary'>{{ item.title }}</div>{% endfor %}"
  end

  let!(:liquid_setting_primary) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      loop_html_setting_type: "snippet",
      state: "public",
      order: 30,
      name: "スニペット/Column Snippet Primary",
      html: snippet_html_primary)
  end

  let!(:liquid_setting_secondary) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      loop_html_setting_type: "snippet",
      state: "public",
      order: 10,
      name: "スニペット/Column Snippet Secondary",
      html: snippet_html_secondary)
  end

  let!(:liquid_setting_closed) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      loop_html_setting_type: "snippet",
      state: "closed",
      name: "スニペット/Column Snippet Closed")
  end

  let!(:liquid_setting_template) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      loop_html_setting_type: "template",
      state: "public",
      order: 15,
      name: "Template Reference",
      html: "{% for item in items %}<div class='template-item'>{{ item.name }}</div>{% endfor %}")
  end

  before do
    login_cms_user
  end

  # スニペットのドロップダウンを取得
  def loop_snippet_select
    find('.loop-snippet-selector', visible: :all)
  end

  # スニペットのドロップダウンから選択
  def select_loop_snippet(option_text)
    select option_text, from: loop_snippet_select[:id]
  end

  # ループHTML（テンプレート参照）のドロップダウンから選択
  def select_template_reference(option_text)
    # カラムでは、ループHTML（テンプレート参照）のドロップダウンのIDが動的
    selector = find('.loop-setting-selector', visible: :all)
    if option_text.blank?
      # 空のオプションを選択する場合は、直接option要素を選択（最初の空のオプションを選択）
      selector.find('option[value=""]', match: :first).select_option
    else
      select option_text, from: selector[:id]
    end
  end

  it "allows inserting liquid snippets into column layout field" do
    visit cms_form_path(site, form)

    click_on I18n.t('cms.buttons.manage_columns')

    within '.gws-column-list-toolbar[data-placement="top"]' do
      wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within '.gws-column-form' do
      fill_in 'item[name]', with: 'Test Column'
      click_on I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

    within_dialog do
      # Wait for the dialog to fully load
      sleep 1

      # スニペットのドロップダウンを確認
      expect(page).to have_css('.loop-snippet-selector', wait: 10) # スニペットのドロップダウン
      # ループHTML（テンプレート参照）のドロップダウンも存在する
      expect(page).to have_css('.loop-setting-selector', visible: :all)

      option_texts = loop_snippet_select.all('option').map(&:text)
      # スニペットドロップダウンでは「スニペット/」プレフィックスが削除される
      snippet_primary_display = liquid_setting_primary.name.sub(/^スニペット\//, "")
      snippet_secondary_display = liquid_setting_secondary.name.sub(/^スニペット\//, "")
      snippet_closed_display = liquid_setting_closed.name.sub(/^スニペット\//, "")
      expect(option_texts).to include(snippet_primary_display)
      expect(option_texts).to include(snippet_secondary_display)
      expect(option_texts).not_to include(snippet_closed_display)

      ordered_names = option_texts.reject(&:blank?)
      expect(ordered_names.index(snippet_secondary_display)).to be < ordered_names.index(snippet_primary_display)

      fill_in_code_mirror 'item[layout]', with: "existing-column-layout"

      # Ensure CodeMirror value is synced to textarea before selecting snippet
      textarea = find('#item_layout', visible: false)
      page.execute_script("$(arguments[0]).data('editor')?.save()", textarea)
      wait_for_js_ready

      # スニペットのドロップダウンから選択
      select_loop_snippet(snippet_secondary_display)

      # Wait for JavaScript to process the change event and insert snippet
      wait_for_js_ready

      textarea_value = find('#item_layout', visible: false).value
      expect(textarea_value).to include("existing-column-layout")
      expect(textarea_value).to include(snippet_html_secondary)
    end
  end

  context "template reference functionality" do
    it "can select liquid loop setting as template reference" do
      visit cms_form_path(site, form)

      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: 'Test Column'
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

      within_dialog do
        # Wait for the dialog to fully load
        wait_for_all_turbo_frames
        sleep 1

        # ループHTML（テンプレート参照）のドロップダウンを確認
        expect(page).to have_css('.loop-setting-selector', visible: :all, wait: 10)
        # スニペットのドロップダウンも存在する
        expect(page).to have_css('.loop-snippet-selector', visible: :all)

        # ループHTML（テンプレート参照）のドロップダウンから選択
        select_template_reference(liquid_setting_template.name)
        wait_for_js_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      # フォーム保存時に loop_setting_id が保存されることを確認
      column = form.columns.where(name: 'Test Column').first
      expect(column).to be_present
      expect(column.loop_setting_id).to eq(liquid_setting_template.id)
      expect(column.loop_setting.html).to eq(liquid_setting_template.html)
    end

    it "template reference and snippet functionality work together" do
      visit cms_form_path(site, form)

      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: 'Test Column With Both'
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

      within_dialog do
        # Wait for the dialog to fully load
        wait_for_all_turbo_frames
        sleep 1

        # スニペットのドロップダウンとループHTML（テンプレート参照）のドロップダウンを区別
        expect(page).to have_css('.loop-snippet-selector', visible: :all, wait: 10) # スニペットのドロップダウン
        expect(page).to have_css('.loop-setting-selector', visible: :all) # ループHTML（テンプレート参照）のドロップダウン

        # まずスニペットのドロップダウンからスニペットを挿入
        snippet_secondary_display = liquid_setting_secondary.name.sub(/^スニペット\//, "")
        fill_in_code_mirror 'item[layout]', with: "custom-content"
        textarea = find('#item_layout', visible: false)
        page.execute_script("$(arguments[0]).data('editor')?.save()", textarea)
        wait_for_js_ready

        select_loop_snippet(snippet_secondary_display) # スニペットのドロップダウンを使用
        wait_for_js_ready

        # その後、ループHTML（テンプレート参照）のドロップダウンからテンプレート参照を選択
        select_template_reference(liquid_setting_template.name) # ループHTML（テンプレート参照）のドロップダウンを使用
        wait_for_js_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      # フォーム保存時に loop_setting_id が保存されることを確認
      column = form.columns.where(name: 'Test Column With Both').first
      expect(column).to be_present
      # Template reference should be set
      expect(column.loop_setting_id).to eq(liquid_setting_template.id)
      # loop_setting_idが設定されている場合、layoutは無視され、loop_setting.htmlが使用される
      expect(column.loop_setting.html).to eq(liquid_setting_template.html)
    end

    it "template reference takes precedence when set before snippet" do
      visit cms_form_path(site, form)

      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: 'Test Column Template First'
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

      within_dialog do
        # Wait for the dialog to fully load
        wait_for_all_turbo_frames
        sleep 1

        # スニペットのドロップダウンとループHTML（テンプレート参照）のドロップダウンを区別
        expect(page).to have_css('.loop-snippet-selector', visible: :all, wait: 10) # スニペットのドロップダウン
        expect(page).to have_css('.loop-setting-selector', visible: :all) # ループHTML（テンプレート参照）のドロップダウン

        # まずループHTML（テンプレート参照）のドロップダウンからテンプレート参照を選択
        select_template_reference(liquid_setting_template.name) # ループHTML（テンプレート参照）のドロップダウンを使用
        wait_for_js_ready
        wait_for_all_turbo_frames

        # ループHTMLが選択されている場合、スニペットのプルダウンが無効になっていることを確認
        snippet_select = find('.loop-snippet-selector', visible: :all)
        expect(snippet_select).to be_disabled

        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      # フォーム保存時に loop_setting_id が保存されることを確認
      column = form.columns.where(name: 'Test Column Template First').first
      expect(column).to be_present
      # Template reference should be set and take precedence over snippet
      expect(column.loop_setting_id).to eq(liquid_setting_template.id)
      # loop_setting_idが設定されている場合、スニペットで挿入された内容は無視され、loop_setting.htmlが使用される
      expect(column.loop_setting.html).to eq(liquid_setting_template.html)
    end

    it "snippet selector is enabled when template reference is not selected" do
      visit cms_form_path(site, form)

      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: 'Test Column Snippet Enabled'
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

      within_dialog do
        # Wait for the dialog to fully load
        wait_for_all_turbo_frames
        sleep 1

        # ループHTMLが選択されていない場合、スニペットのプルダウンが有効になっていることを確認
        snippet_select = find('.loop-snippet-selector', visible: :all)
        expect(snippet_select).not_to be_disabled

        # ループHTMLを選択すると、スニペットのプルダウンが無効になることを確認
        select_template_reference(liquid_setting_template.name)
        wait_for_js_ready
        wait_for_all_turbo_frames

        expect(snippet_select).to be_disabled

        # ループHTMLの選択を解除すると、スニペットのプルダウンが再有効になることを確認
        select_template_reference("")
        wait_for_js_ready
        wait_for_all_turbo_frames

        expect(snippet_select).not_to be_disabled
      end
    end

    context "error handling when loop HTML fails to load" do
      after do
        page.execute_script(<<~JS)
          if (window._originalAjax) {
            if (window.$ && window.$.ajax) {
              window.$.ajax = window._originalAjax;
            }
            delete window._originalAjax;
          }
        JS
      end

      it "displays error message when AJAX request fails with 404" do
        visit cms_form_path(site, form)

        click_on I18n.t('cms.buttons.manage_columns')

        within '.gws-column-list-toolbar[data-placement="top"]' do
          wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within '.gws-column-form' do
          fill_in 'item[name]', with: 'Test Column Error'
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

        within_dialog do
          wait_for_all_turbo_frames
          sleep 1

          # 存在しないループHTML設定のIDを選択するために、削除された設定を作成
          deleted_setting = create(:cms_loop_setting,
            site: site,
            html_format: "liquid",
            state: "public",
            name: "Deleted Template")
          deleted_setting_id = deleted_setting.id
          deleted_setting.destroy

          # ループHTML（テンプレート参照）のドロップダウンから削除された設定を選択
          # ドロップダウンには表示されないので、JavaScriptで直接選択をシミュレート
          page.execute_script(<<~JS)
            var $select = $('.loop-setting-selector');
            var $option = $('<option>', { value: '#{deleted_setting_id}', text: 'Deleted Template' });
            $select.append($option);
            $select.val('#{deleted_setting_id}').trigger('change');
          JS

          # エラーメッセージが表示されることを確認
          expect(page).to have_css('.loop-html-error.errorExplanation', wait: 10)
          expect(page).to have_css('.loop-html-error h2', text: I18n.t("errors.template.header.one"))
          expect(page).to have_css('.loop-html-error p', text: I18n.t("errors.template.body"))
          expect(page).to have_css('.loop-html-error li', text: I18n.t("cms.notices.loop_html_not_found"))
          # アクセシビリティ属性が設定されていることを確認
          error_div = find('.loop-html-error', visible: :all)
          expect(error_div['role']).to eq('alert')
          expect(error_div['aria-live']).to eq('polite')

          # リトライボタンが表示されることを確認
          expect(page).to have_css('.loop-html-error .btn-retry', text: I18n.t("ss.buttons.reload"))

          # テキストエリアがアンロックされていることを確認
          textarea = find('#item_layout', visible: false)
          expect(textarea).not_to be_readonly
        end
      end

      it "displays error message when AJAX request fails with 500" do
        visit cms_form_path(site, form)

        click_on I18n.t('cms.buttons.manage_columns')

        within '.gws-column-list-toolbar[data-placement="top"]' do
          wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within '.gws-column-form' do
          fill_in 'item[name]', with: 'Test Column Server Error'
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

        within_dialog do
          wait_for_all_turbo_frames
          sleep 1

          # サーバーエラーをシミュレートするために、$.ajaxをモック
          page.execute_script(<<~JS)
            // 元の$.ajaxをwindowオブジェクトに保存（グローバルスコープで保持）
            if (!window._originalAjax) {
              window._originalAjax = $.ajax;
            }
            $.ajax = function(options) {
              if (options.url && options.url.includes('loop_setting')) {
                // 500エラーをシミュレート
                options.error({
                  status: 500,
                  statusText: 'Internal Server Error',
                  responseText: 'Server Error'
                }, 'error', 'Internal Server Error');
                return;
              }
              return window._originalAjax.apply(this, arguments);
            };
          JS

          # ループHTML（テンプレート参照）のドロップダウンから選択
          select_template_reference(liquid_setting_template.name)
          wait_for_js_ready

          # エラーメッセージが表示されることを確認
          expect(page).to have_css('.loop-html-error.errorExplanation', wait: 10)
          expect(page).to have_css('.loop-html-error li', text: I18n.t("cms.notices.loop_html_server_error"))
          # アクセシビリティ属性が設定されていることを確認
          error_div = find('.loop-html-error', visible: :all)
          expect(error_div['role']).to eq('alert')
          expect(error_div['aria-live']).to eq('polite')

          # リトライボタンが表示されることを確認
          expect(page).to have_css('.loop-html-error .btn-retry', text: I18n.t("ss.buttons.reload"))

          # リトライボタンがクリック可能であることを確認（実際のクリックは行わない）
          retry_button = find('.loop-html-error .btn-retry')
          expect(retry_button).to be_visible
          expect(retry_button).not_to be_disabled
        end
      end

      it "displays generic error message for other AJAX errors" do
        visit cms_form_path(site, form)

        click_on I18n.t('cms.buttons.manage_columns')

        within '.gws-column-list-toolbar[data-placement="top"]' do
          wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within '.gws-column-form' do
          fill_in 'item[name]', with: 'Test Column Generic Error'
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

        within_dialog do
          wait_for_all_turbo_frames
          sleep 1

          # 一般的なエラーをシミュレート
          page.execute_script(<<~JS)
            // 元の$.ajaxをwindowオブジェクトに保存（グローバルスコープで保持）
            if (!window._originalAjax) {
              window._originalAjax = $.ajax;
            }
            $.ajax = function(options) {
              if (options.url && options.url.includes('loop_setting')) {
                // 403エラーをシミュレート
                options.error({
                  status: 403,
                  statusText: 'Forbidden',
                  responseText: 'Forbidden'
                }, 'error', 'Forbidden');
                return;
              }
              return window._originalAjax.apply(this, arguments);
            };
          JS

          # ループHTML（テンプレート参照）のドロップダウンから選択
          select_template_reference(liquid_setting_template.name)
          wait_for_js_ready

          # エラーメッセージが表示されることを確認
          expect(page).to have_css('.loop-html-error.errorExplanation', wait: 10)
          expect(page).to have_css('.loop-html-error li', text: I18n.t("cms.notices.loop_html_load_error"))

          # アクセシビリティ属性が設定されていることを確認
          error_div = find('.loop-html-error', visible: :all)
          expect(error_div['role']).to eq('alert')
          expect(error_div['aria-live']).to eq('polite')
        end
      end
    end
  end
end
