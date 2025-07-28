require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:item1) { create(:cms_page) }

  before { login_cms_user }

  context "when branches are existed" do
    it do
      visit cms_pages_path(site: site)
      click_on item1.name
      within '#addon-workflow-agents-addons-branch' do
        wait_for_turbo_frame "#workflow-branch-frame"
        wait_for_event_fired "turbo:frame-load" do
          click_on I18n.t("workflow.create_branch")
        end
        expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
        expect(page).to have_css('table.branches')
        expect(page).to have_css('.see.branch', text: item1.name)
      end

      # visit show_path
      click_on I18n.t("ss.links.delete")
      expect(page).to have_css(".addon-head", text: I18n.t('workflow.confirm.unable_to_delete_master_page'))
      within "form" do
        expect(page).to have_no_css(".send", text: I18n.t("ss.buttons.delete"))
      end
    end
  end
end
