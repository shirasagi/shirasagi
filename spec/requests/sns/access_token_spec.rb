require 'spec_helper'
require "csv"

describe "Sns::AccessTokenController", type: :request, dbscope: :example do
  let!(:site) { ss_site }
  let!(:user) { ss_user }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let(:access_token_path) { sns_access_token_path }
  let(:test_path) { sns_connection_path }

  context "user" do
    before do
      # get and save  auth token
      get auth_token_path
      @auth_token = JSON.parse(response.body)["auth_token"]

      # login
      params = {
        'authenticity_token' => @auth_token,
        'item[email]' => user.email,
        'item[password]' => user.in_password
      }
      post sns_login_path(format: :json), params: params
    end

    describe "POST /access_token" do
      it do
        post access_token_path
        token = response.body # ex.) cQHNgMyHfVm3F27U

        expect(response.status).to eq 200
        expect(response.body.size).to be_between(10, 20)

        user.reload
        expect(token).to eq user.access_token

        get "#{test_path}?access_token=#{token}"
        expect(response.status).to eq 302
        expect(response.body).to include test_path
      end
    end
  end
end
