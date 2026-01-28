require 'spec_helper'

describe "cms_role_edits", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  context "basic crud" do
    let!(:role) { create :cms_role, cur_site: site, name: "role-#{unique_id}" }
    let!(:group) { create :cms_group, cur_site: site, name: "#{cms_group.name}/#{unique_id}" }
    let!(:user) { create :cms_test_user, group_ids: [ group.id ] }

    it do
      login_user admin, to: cms_group_path(site: site, id: group)
      click_on I18n.t("ss.role_setting")
      within "form#item-form" do
        expect(page).to have_css("[data-user-id='#{user.id}']", text: user.long_name)

        check role.name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::User.find(user.id).tap do |after_edit|
        expect(after_edit.cms_role_ids).to include(role.id)
      end
    end
  end
end
