require 'spec_helper'

describe 'sns_cur_user_account', type: :request, dbscope: :example do
  let(:user) { create :sys_user_sample }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }

  shared_examples "what sns/user_account is" do
    it "GET /.u/user_account.json" do
      get sns_cur_user_account_path(format: "json"), headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      expect(json["_id"]).to eq user.id
      expect(json["name"]).to eq user.name
      expect(json["email"]).to eq user.email
    end
  end

  context "with jwt bearer grant type with service application" do
    before do
      key = OpenSSL::PKey::RSA.generate(2048)

      application = SS::OAuth2::Application::Service.create!(
        name: unique_id, permissions: [], state: "enabled",
        client_id: SecureRandom.urlsafe_base64(18),
        public_key_type: "rsa",
        public_key_encrypted: SS::Crypto.encrypt(key.public_key.to_pem)
      )

      jwt_assertion = JSON::JWT.new(
        # issuer
        iss: application.client_id,
        # subject
        sub: user.email,
        # scope
        scope: "",
        # audience
        aud: sns_login_oauth2_token_url,
        # expires at
        exp: 1.hour.from_now.to_i,
        # issued at
        iat: Time.zone.now.to_i
      )
      jwt_assertion = jwt_assertion.sign(key)

      token_params = {
        grant_type: SS::OAuth2::TokenRequest::JWTBearer::GRANT_TYPE,
        assertion: jwt_assertion.to_s
      }

      post sns_login_oauth2_token_path, params: token_params

      json = JSON.parse(response.body)
      @headers = {
        "Authorization" => "Bearer #{json["access_token"]}"
      }
    end

    include_context "what sns/user_account is"
  end

  context "with jwt bearer grant type with confidential application" do
    before do
      redirect_uri = "#{unique_url}/cb"
      application = SS::OAuth2::Application::Confidential.create!(
        name: unique_id, permissions: [], state: "enabled",
        client_id: SecureRandom.urlsafe_base64(18), client_secret: SecureRandom.urlsafe_base64(36),
        redirect_uris: redirect_uri
      )

      jwt_assertion = JSON::JWT.new(
        # issuer
        iss: application.client_id,
        # subject
        sub: user.email,
        # scope
        scope: "",
        # audience
        aud: sns_login_oauth2_token_url,
        # expires at
        exp: 1.hour.from_now.to_i,
        # issued at
        iat: Time.zone.now.to_i
      )
      jwt_assertion = jwt_assertion.sign(application.client_secret)

      token_params = {
        grant_type: SS::OAuth2::TokenRequest::JWTBearer::GRANT_TYPE,
        assertion: jwt_assertion.to_s
      }

      post sns_login_oauth2_token_path, params: token_params

      json = JSON.parse(response.body)
      @headers = {
        "Authorization" => "Bearer #{json["access_token"]}"
      }
    end

    include_context "what sns/user_account is"
  end

  context "with implicit grant with confidential application" do
    before do
      # implicit flow の場合、まずはどうにかしてログインする
      get auth_token_path
      auth_token = JSON.parse(response.body)["auth_token"]
      params = {
        'authenticity_token' => auth_token,
        'item[email]' => user.email,
        'item[password]' => "pass"
      }
      post sns_login_path(format: :json), params: params

      # access_token を要求する
      redirect_uri = "#{unique_url}/cb"
      application = SS::OAuth2::Application::Confidential.create!(
        name: unique_id, permissions: [], state: "enabled",
        client_id: SecureRandom.urlsafe_base64(18), client_secret: SecureRandom.urlsafe_base64(36),
        redirect_uris: redirect_uri
      )

      state = SecureRandom.hex(16)
      token_params = {
        response_type: "token",
        client_id: application.client_id,
        redirect_uri: redirect_uri,
        scope: "",
        state: state
      }
      get sns_login_oauth2_authorize_path, params: token_params

      # 同意画面（consent screen）は表示されないので、アクセストークンが応答されるはず
      expect(response.status).to eq 302
      fragment = Addressable::URI.parse(response.location).fragment
      resp = Hash[URI.decode_www_form(fragment)]
      @headers = {
        "Authorization" => "Bearer #{resp["access_token"]}"
      }
    end

    include_context "what sns/user_account is"
  end

  context "with authorization code grant with confidential application" do
    before do
      # authorization code flow の場合、まずはどうにかしてログインする
      get auth_token_path
      auth_token = JSON.parse(response.body)["auth_token"]
      params = {
        'authenticity_token' => auth_token,
        'item[email]' => user.email,
        'item[password]' => "pass"
      }
      post sns_login_path(format: :json), params: params

      # access_token を要求する
      redirect_uri = "#{unique_url}/cb"
      application = SS::OAuth2::Application::Confidential.create!(
        name: unique_id, permissions: [], state: "enabled",
        client_id: SecureRandom.urlsafe_base64(18), client_secret: SecureRandom.urlsafe_base64(36),
        redirect_uris: redirect_uri
      )

      state = SecureRandom.hex(16)
      code_params = {
        response_type: "code",
        client_id: application.client_id,
        redirect_uri: redirect_uri,
        scope: "",
        state: state
      }
      get sns_login_oauth2_authorize_path, params: code_params

      expect(response.status).to eq 302 # 現在の実装では同意画面（consent screen）は表示されない
      location_url = Addressable::URI.parse(response.location)
      code = location_url.query_values["code"]

      authorization_code_params = {
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri
      }
      authorization_code_headers = {
        "Authorization" => "Basic #{Base64.encode64([ application.client_id, application.client_secret ].join(":"))}"
      }
      post sns_login_oauth2_token_path, params: authorization_code_params, headers: authorization_code_headers

      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      @headers = {
        "Authorization" => "Bearer #{json["access_token"]}"
      }
    end

    include_context "what sns/user_account is"
  end
end
