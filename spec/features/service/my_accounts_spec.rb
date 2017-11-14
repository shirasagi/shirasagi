require 'spec_helper'

describe "service_my_accounts", type: :feature, dbscope: :example do
  let(:user) { create :service_account_admin }
  let(:item) { create :service_account }
  let(:index_path) { service_my_accounts_path }

  context "without auth" do
    before { login_service_account(item) }

    it "#show" do
      visit index_path
      expect(status_code).to eq 200
    end
  end

  context "with auth" do
    before { login_service_account(user) }

    it "#show" do
      visit index_path
      expect(status_code).to eq 200
    end
  end
end
