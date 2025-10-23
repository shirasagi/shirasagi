require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let(:snippet_html_primary) { "{% for item in items %}<div class='column-snippet-primary'>{{ item.name }}</div>{% endfor %}" }
  let(:snippet_html_secondary) { "{% for item in items %}<div class='column-snippet-secondary'>{{ item.title }}</div>{% endfor %}" }

  let!(:liquid_setting_primary) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      state: "public",
      order: 30,
      name: "Column Snippet Primary",
      html: snippet_html_primary)
  end

  let!(:liquid_setting_secondary) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      state: "public",
      order: 10,
      name: "Column Snippet Secondary",
      html: snippet_html_secondary)
  end

  let!(:liquid_setting_closed) do
    create(:cms_loop_setting,
      site: site,
      html_format: "liquid",
      state: "closed",
      name: "Column Snippet Closed")
  end

  before do
    login_cms_user
  end

  it "allows inserting liquid snippets into column layout field" do
    visit cms_form_path(site, form)

    click_on I18n.t('cms.buttons.manage_columns')

    within '.gws-column-list-toolbar[data-placement="top"]' do
      wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/free') }
    end
    wait_for_notice I18n.t('ss.notice.saved')

    wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }

    within_dialog do
      ensure_addon_opened('#addon-cms-agents-addons-column_layout')

      expect(page).to have_select('loop_snippet_selector', wait: 5)

      option_texts = find('#loop_snippet_selector').all('option').map(&:text)
      expect(option_texts).to include(liquid_setting_primary.name)
      expect(option_texts).to include(liquid_setting_secondary.name)
      expect(option_texts).not_to include(liquid_setting_closed.name)

      ordered_names = option_texts.reject(&:blank?)
      expect(ordered_names.index(liquid_setting_secondary.name)).to be < ordered_names.index(liquid_setting_primary.name)

      fill_in_code_mirror 'item[layout]', with: "existing-column-layout"

      select liquid_setting_secondary.name, from: 'loop_snippet_selector'

      expect(find('#loop_snippet_selector').value).to eq ""

      textarea_value = find('#item_layout', visible: false).value
      expect(textarea_value).to include("existing-column-layout")
      expect(textarea_value).to include(snippet_html_secondary)
    end
  end
end
