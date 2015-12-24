require 'spec_helper'

describe "webapi login", dbscope: :example, type: :request do
  before do
    SS.config.replace_value_at(:env, :protect_csrf, false)
  end

  let!(:site) { cms_site }
  let!(:user) { cms_user }

  ## paths
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:logout_path) { sns_logout_path(format: :json) }

  ## request params
  let!(:correct_login_params) do
    {
      :item => {
        :email => user.email,
        :password => SS::Crypt.encrypt("pass", type: "AES-256-CBC"),
        :encryption_type => "AES-256-CBC"
      }
    }
  end
  let!(:invalid_login_params) do
    {
      :item => {
        :email => user.email,
        :password => "pass",
        :encryption_type => "AES-256-CBC"
      }
    }
  end

  context "login" do
    describe "POST /.mypage/login.json" do
      it "422" do
        post login_path, invalid_login_params
        expect(response.status).to eq 422
      end

      it "204" do
        post login_path, correct_login_params
        expect(response.status).to eq 204
      end
    end
  end

  context "logout" do
    describe "GET /.mypage/logout.json" do
      it "401" do
        get logout_path
        expect(response.status).to eq 401
      end

      it "204" do
        post login_path, correct_login_params
        expect(response.status).to eq 204

        get logout_path
        expect(response.status).to eq 204
      end
    end
  end
end
