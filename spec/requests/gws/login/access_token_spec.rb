require 'spec_helper'
require "csv"

describe "Gws::LoginController#access_token", type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let(:access_token_path) { gws_access_token_path(site: site) }
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
        'item[password]' => "pass"
      }
      post sns_login_path(format: :json), params: params
    end

    describe "POST /access_token" do
      it do
        post access_token_path
        token = response.body # ex.) cQHNgMyHfVm3F27U

        expect(response.status).to eq 200
        expect(response.body.size).to be_between(10, 20)

        get "#{test_path}?access_token=#{token}"
        expect(response.status).to eq 302
        expect(response.location).to include test_path
      end
    end
  end
end
