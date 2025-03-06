require 'spec_helper'

describe "gws_personal_address_management_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_personal_address_management_groups_path(site) }

  context "with auth" do
    let!(:item) { create :webmail_address_group, cur_user: gws_user }

    before { login_gws_user }

    it_behaves_like 'crud flow'
  end

  context "with a user who is allowed only to use personal address" do
    let(:role) do
      Gws::Role.create!(
        name: unique_id, site_id: gws_site.id, permissions: %w(edit_gws_personal_addresses)
      )
    end
    let(:uid) { unique_id }
    let(:user) do
      Gws::User.create!(
        name: uid, uid: uid, email: "#{uid}@example.jp", in_password: "pass",
        group_ids: [gws_site.id], gws_role_ids: [role.id],
        lang: SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s
      )
    end

    before { login_user(user) }

    it do
      visit gws_portal_path(site: site)

      within ".main-navi" do
        click_on I18n.t('modules.gws/personal_address')
      end

      within '.mod-navi.current-navi' do
        click_on I18n.t("gws/personal_address.navi.group")
      end

      expect(page).to have_content(I18n.t("ss.links.new"))
    end
  end
end
