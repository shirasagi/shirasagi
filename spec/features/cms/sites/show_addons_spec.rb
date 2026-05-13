require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user1) { create :cms_user, name: unique_id, group_ids: cms_user.group_ids, cms_role_ids: [role1.id] }
  let!(:user2) { create :cms_user, name: unique_id, group_ids: cms_user.group_ids, cms_role_ids: [role2.id] }

  let!(:user_permissions1) { Cms::Role.permission_names.select { |n| n =~ /_(private|other)_/ } }
  let!(:user_permissions2) { Cms::Role.permission_names.select { |n| n =~ /_(private|other)_/ } + %w(edit_cms_sites) }

  let!(:role1) { create :cms_role, cur_site: site, name: unique_id, permissions: user_permissions1 }
  let!(:role2) { create :cms_role, cur_site: site, name: unique_id, permissions: user_permissions2 }

  let(:show_path) { cms_site_path site }

  context "with cms_user (admin)" do
    before { login_cms_user }

    it do
      visit show_path
      within ".addon-views" do
        expect(page).to have_css("#addon-basic")
        expect(page).to have_selector(".addon-view", minimum: 2)
      end
      within "#menu" do
        expect(page).to have_link(I18n.t("ss.links.edit"))
      end
    end
  end

  context "with user1" do
    before { login_user(user1) }

    it do
      visit show_path
      within ".addon-views" do
        expect(page).to have_css("#addon-basic")
        expect(page).to have_selector(".addon-view", count: 1)
      end
      within "#menu" do
        expect(page).to have_no_link(I18n.t("ss.links.edit"))
      end
    end
  end

  context "with user2" do
    before { login_user(user2) }

    it do
      visit show_path
      within ".addon-views" do
        expect(page).to have_css("#addon-basic")
        expect(page).to have_selector(".addon-view", minimum: 2)
      end
      within "#menu" do
        expect(page).to have_link(I18n.t("ss.links.edit"))
      end
    end
  end
end
