require 'spec_helper'
require 'csv'

RSpec.describe Sys::UsersController, type: :controller do
  let(:site) { create(:cms_site) }
  let(:group) { create(:ss_group, name: "Test Group") }
  let(:role) { create(:sys_role, name: "Test Role") }
  let(:organization) { create(:ss_group, name: "Test Organization") }
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
           initial_password_warning: true,
           group_ids: [group.id],
           sys_role_ids: [role.id],
           organization_id: organization.id,
           last_loggedin: "2025-01-28 12:00:00")
  end

  before do
    @cur_user = user
    @cur_site = site
    @model = SS::User
    allow(controller).to receive(:@cur_user).and_return(@cur_user)
    allow(controller).to receive(:@cur_site).and_return(@cur_site)
    allow(controller).to receive(:@model).and_return(@model)
  end

  describe 'GET #download_all' do
    it 'returns a CSV file' do
      get :download_all, params: { s: { state: 'all' } }

      expect(response).to have_http_status(302)
      # expect(response.header['Content-Type']).to include 'text/csv'
      # expect(response.header['Content-Disposition']).to include "attachment; filename=\"sys_users_#{Time.zone.now.to_i}.csv\""

      csv_data = CSV.parse(response.body, headers: true)
      expect(csv_data.length).to eq(1)
      expect(csv_data.headers).to include(*SS::User.csv_headers)

      row = csv_data.first
      expect(row["id"]).to eq(user.id.to_s)
      expect(row["name"]).to eq(user.name)
      expect(row["kana"]).to eq(user.kana)
      expect(row["uid"]).to eq(user.uid)
      expect(row["organization_uid"]).to eq(user.organization_uid)
      expect(row["email"]).to eq(user.email)
      expect(row["password"]).to be_nil
      expect(row["tel"]).to eq(user.tel)
      expect(row["tel_ext"]).to eq(user.tel_ext)
      expect(row["account_start_date"]).to eq(I18n.l(user.account_start_date, format: :default))
      expect(row["account_expiration_date"]).to eq(I18n.l(user.account_expiration_date, format: :default))
      expect(row["initial_password_warning"]).to eq(I18n.t('ss.options.state.enabled'))
      expect(row["organization_id"]).to eq(organization.id.to_s)
      expect(row["groups"]).to eq(group.name)
      expect(row["last_loggedin"]).to eq(user.last_loggedin.to_s)
      unless Sys::Auth::Setting.instance.mfa_otp_use_none?
        expect(row["mfa_otp_enabled_at"]).to be_nil
      end
      expect(row["sys_roles"]).to eq(role.name)
    end
  end
end