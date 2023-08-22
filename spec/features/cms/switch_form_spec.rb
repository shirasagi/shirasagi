require 'spec_helper'

describe 'フォルダー直下', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :cms_node_page, cur_site: site, group_ids: [cms_group.id] }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let(:item) { create :cms_page, cur_site: site, cur_node: node, html: html }

  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end
  let(:name) { unique_id }
  let(:column1_value) { unique_id }
  let(:html) { "<p>#{unique_id}</p>" }

  before do
    node.st_form_ids = [form.id]
    node.save!
  end

  context '定型フォームが選択できているか確認' do
    before { login_cms_user }
    it do
      visit new_cms_page_path(site.id)

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select("#{form.name}", from: "in_form_id")
          end
        end
        click_on I18n.t('ss.buttons.draft_save')
      end
      
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_no_css("#addon-cms-agents-addons-body")
      expect(page).to have_content("定型フォーム")
      expect(page).to have_content(form.name)
    end
  end
end
