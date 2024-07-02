require 'spec_helper'

describe "/.mypage/status", dbscope: :example, type: :request do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  ## paths
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:logout_path) { sns_logout_path(format: :json) }

  ## request params
  let!(:login_params) do
    {
      :item => {
        :email => user.email,
        :password => SS::Crypto.encrypt("pass", type: "AES-256-CBC"),
        :encryption_type => "AES-256-CBC"
      }
    }
  end

  context "login -> logout" do
    it do
      get sns_login_status_path
      expect(response.status).to eq 403
      expect(response.headers["Retry-After"]).to be_blank

      post login_path, params: login_params
      expect(response.status).to eq 204

      get sns_login_status_path
      expect(response.status).to eq 200
      expect(response.headers["Retry-After"]).to be_numeric
      retry_after = response.headers["Retry-After"].to_i
      expect(retry_after).to be > 0

      get logout_path

      get sns_login_status_path
      expect(response.status).to eq 403
      expect(response.headers["Retry-After"]).to be_blank
    end
  end

  context "login -> session timeout" do
    it do
      get sns_login_status_path
      expect(response.status).to eq 403
      expect(response.headers["Retry-After"]).to be_blank

      post login_path, params: login_params
      expect(response.status).to eq 204

      get sns_login_status_path
      expect(response.status).to eq 200
      expect(response.headers["Retry-After"]).to be_numeric
      retry_after = response.headers["Retry-After"].to_i
      Timecop.travel(Time.zone.now + retry_after.seconds) do
        get sns_login_status_path
        expect(response.status).to eq 403
        expect(response.headers["Retry-After"]).to be_blank
      end
    end
  end
end
