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

      within "#menu" do
        within "nav" do
          click_on I18n.t("ss.links.download")
        end
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        csv_data = CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
        expect(csv_data.length).to eq 3
        expected_headers = %w(
          id name kana uid organization_uid email password tel tel_ext
          account_start_date account_expiration_date initial_password_warning organization_id groups DN sys_roles
        ).map { |header| I18n.t("mongoid.attributes.ss/model/user.#{header}", default: header) }
        expect(csv_data.headers).to include(*expected_headers)

        row = csv_data[-1]
        expect(row[I18n.t("mongoid.attributes.ss/model/user.name", default: "name")]).to eq(user.name)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.kana", default: "kana")]).to eq(user.kana)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.uid", default: "uid")]).to eq(user.uid)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.organization_uid",
default: "organization_uid")]).to eq(user.organization_uid)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.email", default: "email")]).to eq(user.email)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.password", default: "password")]).to be_blank
        expect(row[I18n.t("mongoid.attributes.ss/model/user.tel", default: "tel")]).to eq(user.tel)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.tel_ext", default: "tel_ext")]).to eq(user.tel_ext)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.account_start_date",
default: "account_start_date")]).to eq(I18n.l(user.account_start_date, format: :default))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.account_expiration_date",
default: "account_expiration_date")]).to eq(I18n.l(user.account_expiration_date, format: :default))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.initial_password_warning",
default: "initial_password_warning")]).to eq(I18n.t('ss.options.state.enabled'))
        expect(row[I18n.t("mongoid.attributes.ss/model/user.organization_id",
default: "organization_id")]).to eq(organization.name)
        expect(row[I18n.t("mongoid.attributes.ss/model/user.groups", default: "groups")]).to eq(group.name)
        expect(row['DN']).to eq(user.ldap_dn)
        unless Sys::Auth::Setting.instance.mfa_otp_use_none?
          expect(row[I18n.t("mongoid.attributes.ss/model/user.mfa_otp_enabled_at", default: "mfa_otp_enabled_at")]).to be_nil
        end
        expect(row[I18n.t("mongoid.attributes.ss/model/user.sys_roles", default: "sys_roles")]).to eq(role.name)
      end
    end
  end
end
