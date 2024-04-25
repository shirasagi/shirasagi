require 'spec_helper'

describe 'chorg_results', type: :feature, dbscope: :example, js: true do
  context "ss-4410" do
    let!(:group1) { create :cms_group, name: unique_id }
    let!(:group2) { create :cms_group, name: unique_id }
    let!(:site1) { create :cms_site_unique, group_ids: [ group1.id ] }
    let!(:site2) { create :cms_site_unique, group_ids: [ group2.id ] }
    let!(:role1) { create :cms_role_admin, site_id: site1.id }
    let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ role1.id ] }

    before { login_user user1 }

    it do
      visit chorg_main_path(site: site1)
      click_on I18n.t("ss.links.new")
      wait_for_cbox_opened do
        click_on I18n.t("cms.apis.sites.index")
      end
      within_cbox do
        expect(page).to have_css(".list-item", text: site1.name)
        expect(page).to have_no_content(site2.name)
      end
    end
  end
end
