require 'spec_helper'

describe 'フォルダー直下', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end

  before { login_cms_user }

  context '定型フォームが選択できているか確認' do
    let(:name) { unique_id }
    let(:column1_value) { unique_id }
    let(:html) { "<p>#{unique_id}</p>" }

    it do
      visit new_cms_page_path(site.id)

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select(form.name, from: "in_form_id")
          end
        end
        click_on I18n.t('ss.buttons.draft_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_no_css("#addon-cms-agents-addons-body")
      expect(page).to have_content("定型フォーム")
      expect(page).to have_content(form.name)
    end
  end
end
