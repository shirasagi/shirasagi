require 'spec_helper'
require 'csv'

describe Sys::UsersController, type: :request, dbscope: :example, js: true do
  let(:site) { create(:cms_site) }
  let(:group) { create(:ss_group, name: "Test Group") }
  let(:role) { create(:sys_role, name: "Test Role") }
  let(:organization) { create(:ss_group, name: "Test Organization") }
  let(:index_path) { sys_users_path(site.id) }
  let(:new_path) { new_sys_user_path(site.id) }
  let(:download_path) { download_all_sys_users_path(site.id) }
  let(:user) do
    create(:sys_user_sample_2,
           name: "John Doe",
           kana: "ジョン・ドウ",
           uid: "johndoe",
           organization_uid: "org-001",
           email: "johndoe@example.com",
           tel: "123-456-7890",
           tel_ext: "1234",
           account_start_date: "2025-01-01",
           account_expiration_date: "2025-12-31",
           initial_password_warning: 1,
           session_lifetime: 3600,
           restriction: "api_only",
           lock_state: "locked",
           deletion_lock_state: "unlocked",
           type: SS::Model::User::TYPE_SSO,
           remark: "Test Remark",
           lang: "ja",
           timezone: "Asia/Tokyo",
           in_password: nil,
           group_ids: [group.id],
           sys_role_ids: [role.id],
           organization_id: organization.id,
           ldap_dn: "uid=johndoe,ou=users,dc=example,dc=com")
  end

  before do
    login_sys_user
    user
  end

  context "users download" do
    it do
      visit index_path
      # #item-form > footer > input

      within "#menu" do
        within "nav" do
          click_on I18n.t("ss.links.download")
        end
      end

      within "#item-form" do
        within "footer" do
          click_on I18n.t("ss.links.download")
        end
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        csv_data = CSV.read(downloads.first, headers: true, encoding: 'BOM|UTF-8')

        expect(csv_data.length).to eq 3
        expected_headers = %w[id] + %w(
         id name kana uid organization_uid email password tel tel_ext type account_start_date account_expiration_date
         initial_password_warning session_lifetime restriction lock_state deletion_lock_state organization_id groups remark
        ).map { |header| I18n.t("mongoid.attributes.ss/model/user.#{header}") }

        expected_headers += [
          I18n.t("modules.addons.ss/locale_setting"),
          I18n.t("mongoid.attributes.ss/addon/locale_setting.timezone"),
          "DN"
        ]

        expect(csv_data.headers).to include(*expected_headers)

        row = csv_data[-1]
        expect(row[I18n.t("mongoid.attributes.ss/model/user.name")]).to eq(user.name)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.kana")]).to eq(user.kana)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.uid")]).to eq(user.uid)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.organization_uid")]).to eq(user.organization_uid)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.email")]).to eq(user.email)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.password")]).to be_blank
        expect(row[I18n.t("mongoid.attributes.ss/model/user.tel")]).to eq(user.tel)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.tel_ext")]).to eq(user.tel_ext)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.type")]).to eq(I18n.t("ss.options.user_type.sso"))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.session_lifetime")]).to eq("3600")
        expect(row[I18n.t("mongoid.attributes.ss/model/user.restriction")]).to eq(I18n.t("ss.options.restriction.api_only"))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.lock_state")]).to eq(I18n.t("ss.options.user_lock_state.locked"))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.deletion_lock_state")]).to \
          eq(I18n.t("ss.options.user_deletion_lock_state.unlocked"))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.account_start_date")]).to \
          eq(I18n.l(user.account_start_date))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.account_expiration_date")]).to \
          eq(I18n.l(user.account_expiration_date))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.initial_password_warning")]).to eq(I18n.t('ss.options.state.enabled'))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.organization_id")]).to eq(organization.name)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.groups")]).to eq(group.name)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.remark")]).to eq(user.remark)
        unless Sys::Auth::Setting.instance.mfa_otp_use_none?
          expect(row[I18n.t("mongoid.attributes.ss/model/user.mfa_otp_enabled_at")]).to be_nil
        end
        expect(row[I18n.t("modules.addons.ss/locale_setting")]).to eq(I18n.t("ss.options.lang.ja"))
        expect(row[I18n.t("mongoid.attributes.ss/addon/locale_setting.timezone")]).to eq(user.timezone)
        expect(row['DN']).to eq(user.ldap_dn)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.sys_roles")]).to eq(role.name)
      end
    end
  end
end
