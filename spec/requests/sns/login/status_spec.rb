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

  it do
    get sns_login_status_path
    expect(response.status).to eq 403
    expect(response.headers["Retry-After"]).to be_blank

    post login_path, params: login_params

    get sns_login_status_path
    expect(response.status).to eq 200
    expect(response.headers["Retry-After"]).to be_present
    expect(response.headers["Retry-After"]).to be_numeric

    get logout_path

    get sns_login_status_path
    expect(response.status).to eq 403
    expect(response.headers["Retry-After"]).to be_blank
  end

  # context "login" do
  #   describe "POST /.mypage/login.json" do
  #     it "422" do
  #       post login_path, params: invalid_login_params
  #       expect(response.status).to eq 422
  #     end
  #
  #     it "204" do
  #       post login_path, params: correct_login_params
  #       expect(response.status).to eq 204
  #     end
  #   end
  # end
  #
  # context "logout" do
  #   describe "GET /.mypage/logout.json" do
  #     it "401" do
  #       get logout_path
  #       expect(response.status).to eq 401
  #     end
  #
  #     it "204" do
  #       post login_path, params: correct_login_params
  #       expect(response.status).to eq 204
  #
  #       get logout_path
  #       expect(response.status).to eq 204
  #     end
  #   end
  # end
end
