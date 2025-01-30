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
    create(:sys_user_sample,
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
           last_loggedin: "2025-01-28 12:00:00")
  end

  before do
    login_sys_user
    user
  end

  context "users download" do
    it do
      visit index_path

      # require 'pry-byebug'
      # binding.pry

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
          id 氏名 カナ ユーザーID 職員番号 メールアドレス パスワード 電話番号 内線番号
          有効期限（開始） 有効期限（終了） 初期パスワード警告 所属組織 グループ 最終ログイン日時 SYSロール
        )
        expect(csv_data.headers).to include(*expected_headers)

        row = csv_data[-1]
        expect(row["氏名"]).to eq(user.name)
        expect(row["カナ"]).to eq(user.kana)
        expect(row["ユーザーID"]).to eq(user.uid)
        expect(row["職員番号"]).to eq(user.organization_uid)
        expect(row["メールアドレス"]).to eq(user.email)
        expect(row["パスワード"]).to be_nil
        expect(row["電話番号"]).to eq(user.tel)
        expect(row["内線番号"]).to eq(user.tel_ext)
        expect(row["有効期限（開始）"]).to eq(I18n.l(user.account_start_date, format: :default))
        expect(row["有効期限（終了）"]).to eq(I18n.l(user.account_expiration_date, format: :default))
        expect(row["初期パスワード警告"]).to eq(I18n.t('ss.options.state.enabled'))
        expect(row["所属組織"]).to eq(organization.name)
        expect(row["グループ"]).to eq(group.name)
        expect(row["最終ログイン日時"]).to eq(user.last_loggedin.to_s)
        unless Sys::Auth::Setting.instance.mfa_otp_use_none?
          expect(row["mfa_otp_enabled_at"]).to be_nil
        end
        expect(row["SYSロール"]).to eq(role.name)
      end
    end
  end
end