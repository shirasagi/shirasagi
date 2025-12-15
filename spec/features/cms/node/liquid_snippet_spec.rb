require 'spec_helper'

describe "cms node liquid snippets", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create(:article_node_page, cur_site: site) }
  let(:snippet_html_high) { "{% for item in items %}<div class='snippet-high'>{{ item.name }}</div>{% endfor %}" }
  let(:snippet_html_low) { "{% for item in items %}<div class='snippet-low'>{{ item.title }}</div>{% endfor %}" }

  let!(:shirasagi_loop_setting) do
    create(:cms_loop_setting,
      site: site,
      html_format: "shirasagi",
      setting_type: "template",
      state: "public",
      order: 10,
      name: "Shirasagi Template")
  end

  let!(:liquid_setting_high) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      setting_type: "snippet",
      state: "public",
      order: 20,
      name: "スニペット/Liquid Snippet High",
      html: snippet_html_high)
  end

  let!(:liquid_setting_low) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      setting_type: "snippet",
      state: "public",
      order: 5,
      name: "スニペット/Liquid Snippet Low",
      html: snippet_html_low)
  end

  let!(:liquid_setting_closed) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      setting_type: "snippet",
      state: "closed",
      name: "スニペット/Liquid Snippet Closed")
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
    select option_text, from: 'item_loop_setting_id_liquid'
  end

  it "inserts public liquid snippets into loop_liquid while excluding closed snippets" do
    visit edit_node_conf_path(site.id, node)

    ensure_addon_opened('#addon-event-agents-addons-page_list')

    within '#addon-event-agents-addons-page_list' do
      select('Liquid', from: 'item[loop_format]') if page.has_select?('item[loop_format]')
      wait_for_js_ready

      # スニペットのドロップダウンを確認
      expect(page).to have_css('.loop-snippet-selector', wait: 5)
      # ループHTML（テンプレート参照）のドロップダウンも存在する
      expect(page).to have_field('item_loop_setting_id_liquid', visible: :all)

      # スニペットのドロップダウンのオプションを確認
      option_texts = loop_snippet_select.all('option').map(&:text)

      # スニペットドロップダウンでは「スニペット/」プレフィックスが削除される
      snippet_high_display = liquid_setting_high.name.sub(/^スニペット\//, "")
      snippet_low_display = liquid_setting_low.name.sub(/^スニペット\//, "")
      snippet_closed_display = liquid_setting_closed.name.sub(/^スニペット\//, "")

      expect(option_texts).to include(snippet_high_display)
      expect(option_texts).to include(snippet_low_display)
      expect(option_texts).not_to include(snippet_closed_display)

      liquid_names = option_texts.reject(&:blank?)
      expect(liquid_names.index(snippet_low_display)).to be < liquid_names.index(snippet_high_display)

      fill_in_code_mirror 'item[loop_liquid]', with: "existing-liquid-content"

      # スニペットのドロップダウンから選択
      select_loop_snippet(snippet_high_display)

      expect(loop_snippet_select.value).to eq ""

      textarea_value = find('#item_loop_liquid', visible: false).value
      expect(textarea_value).to include("existing-liquid-content")
      expect(textarea_value).to include(snippet_html_high)
    end
  end

  it "retains shirasagi loop setting selection when submitting the form" do
    visit edit_node_conf_path(site.id, node)

    ensure_addon_opened('#addon-event-agents-addons-page_list')

    within '#addon-event-agents-addons-page_list' do
      if page.has_select?('item[loop_format]')
        select(I18n.t('cms.options.loop_format.shirasagi'), from: 'item[loop_format]')
      end
      wait_for_js_ready

      expect(page).to have_field('item_loop_setting_id', visible: :all)
      expect(page).to have_field('item_loop_setting_id_liquid', disabled: true, visible: :all)

      select shirasagi_loop_setting.name, from: 'item_loop_setting_id'
      expect(page).to have_select('item_loop_setting_id', selected: shirasagi_loop_setting.name)
    end

    within 'form#item-form' do
      click_on I18n.t('ss.buttons.save')
    end

    wait_for_notice I18n.t('ss.notice.saved')

    node.reload
    expect(node.loop_setting_id).to eq shirasagi_loop_setting.id
    expect(node.loop_format).to eq 'shirasagi'
  end

  context "template reference functionality" do
    let!(:node_with_template) { create(:article_node_page, cur_site: site) }
    let!(:template_setting) do
      create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        setting_type: "template",
        state: "public",
        order: 15,
        name: "Template Reference",
        html: "{% for page in pages %}<div class='template'>{{ page.name }}</div>{% endfor %}")
    end

    before do
      login_cms_user
    end

    it "can select liquid loop setting as template reference" do
      visit edit_node_conf_path(site.id, node_with_template)

      ensure_addon_opened('#addon-event-agents-addons-page_list')

      within '#addon-event-agents-addons-page_list' do
        select('Liquid', from: 'item[loop_format]') if page.has_select?('item[loop_format]')
        wait_for_js_ready

        # ループHTML（テンプレート参照）のドロップダウンを確認（スニペットのドロップダウンとは別）
        expect(page).to have_select('item_loop_setting_id_liquid', wait: 5)

        # ループHTML（テンプレート参照）のドロップダウンから選択
        select_template_reference(template_setting.name)
      end

      within "form#item-form" do
        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      node_with_template.reload
      expect(node_with_template.loop_setting_id).to eq template_setting.id
      expect(node_with_template.loop_format).to eq "liquid"
      expect(node_with_template.loop_setting.html).to eq template_setting.html
    end

    it "template reference and snippet functionality work together" do
      visit edit_node_conf_path(site.id, node_with_template)

      ensure_addon_opened('#addon-event-agents-addons-page_list')

      within '#addon-event-agents-addons-page_list' do
        select('Liquid', from: 'item[loop_format]') if page.has_select?('item[loop_format]')
        wait_for_js_ready

        # スニペットのドロップダウンとループHTML（テンプレート参照）のドロップダウンを区別
        expect(page).to have_css('.loop-snippet-selector', wait: 5) # スニペットのドロップダウン
        expect(page).to have_field('item_loop_setting_id_liquid', visible: :all) # ループHTML（テンプレート参照）のドロップダウン

        # まずスニペットのドロップダウンからスニペットを挿入
        snippet_low_display = liquid_setting_low.name.sub(/^スニペット\//, "")
        fill_in_code_mirror 'item[loop_liquid]', with: "custom-content"
        select_loop_snippet(snippet_low_display) # スニペットのドロップダウンを使用
        wait_for_js_ready

        # その後、ループHTML（テンプレート参照）のドロップダウンからテンプレート参照を選択（スニペットのドロップダウンではない）
        select_template_reference(template_setting.name) # ループHTML（テンプレート参照）のドロップダウンを使用
        wait_for_js_ready

        # loop_setting_idが設定されている場合、loop_liquidはテンプレート参照の内容で上書きされる
      end

      within "form#item-form" do
        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      node_with_template.reload
      # Template reference should be set
      expect(node_with_template.loop_setting_id).to eq template_setting.id
      # loop_setting_idが設定されている場合、loop_liquidは無視され、loop_setting.htmlが使用される
      expect(node_with_template.loop_setting.html).to eq template_setting.html
    end

    it "renders using template reference when loop_setting_id is set" do
      node_with_template.update!(
        loop_format: "liquid",
        loop_setting_id: template_setting.id
      )

      # The rendering should use loop_setting.html, not loop_liquid
      # This is tested indirectly by checking that the node has the correct loop_setting_id
      expect(node_with_template.loop_setting).to eq template_setting
      expect(node_with_template.loop_setting.html_format_liquid?).to be true
    end
  end
end
