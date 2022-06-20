require 'spec_helper'

describe 'gws_presence_users', type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:custom_group) { create :gws_custom_group, member_ids: [user.id] }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let(:users_path) { gws_presence_apis_users_path(site: site.id, format: :json) }
  let(:group_users_path) do
    gws_presence_apis_group_users_path(site: site.id, group: gws_user.gws_default_group.id, format: :json)
  end
  let(:custom_group_users_path) do
    gws_presence_apis_custom_group_users_path(site: site.id, group: custom_group.id, format: :json)
  end
  let(:update_path) { gws_presence_apis_user_path(site: site.id, id: gws_user.id, format: :json) }
  let(:states_path) { states_gws_presence_apis_users_path(site: site.id, format: :json) }
  let(:presence_states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }
  let(:presence_styles) { Gws::UserPresence.new.state_styles }

  shared_examples "what gws presence is" do
    it "GET /.g:site/presence/users.json" do
      get users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][1]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
    end

    it "GET /.g:site/presence/g-:group/users.json" do
      get group_users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][1]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
    end

    it "GET /.g:site/presence/c-:group/users.json" do
      get custom_group_users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][0]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
    end

    it "PUT /.g:site/presence/users.json" do
      params = {
        presence_state: "available",
        presence_memo: "modified-memo",
        presence_plan: "modified-plan"
      }
      put update_path, params: params, headers: @headers
      expect(response.status).to eq 200
      gws_admin = JSON.parse(response.body)
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
      expect(gws_admin["presence_state"]).to eq "available"
      expect(gws_admin["presence_state_label"]).to eq presence_states["available"]
      expect(gws_admin["presence_state_style"]).to eq presence_styles["available"]
      expect(gws_admin["presence_memo"]).to eq "modified-memo"
      expect(gws_admin["presence_plan"]).to eq "modified-plan"
      expect(gws_admin["editable"]).to eq true

      get group_users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][1]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
      expect(gws_admin["presence_state"]).to eq "available"
      expect(gws_admin["presence_state_label"]).to eq presence_states["available"]
      expect(gws_admin["presence_state_style"]).to eq presence_styles["available"]
      expect(gws_admin["presence_memo"]).to eq "modified-memo"
      expect(gws_admin["presence_plan"]).to eq "modified-plan"
      expect(gws_admin["editable"]).to eq true
    end

    it "GET /.g:site/presence/users/states.json" do
      get states_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      available = json["items"][0]
      expect(available["name"]).to eq "available"
      expect(available["label"]).to eq presence_states["available"]
      expect(available["style"]).to eq presence_styles["available"]
      expect(available["order"]).to eq 0
    end
  end

  context "login with gws-admin" do
    before do
      # get and save  auth token
      get auth_token_path
      auth_token = JSON.parse(response.body)["auth_token"]
      @headers = nil

      # login
      params = {
        'authenticity_token' => auth_token,
        'item[email]' => gws_user.email,
        'item[password]' => "pass"
      }
      post sns_login_path(format: :json), params: params
    end

    include_context "what gws presence is"
  end

  context "token auth with gws-admin" do
    context "with jwt bearer grant type with service application" do
      before do
        key = OpenSSL::PKey::RSA.generate(2048)

        application = SS::OAuth2::Application::Service.create!(
          name: unique_id, permissions: Gws::Role.permission_names, state: "enabled",
          client_id: SecureRandom.urlsafe_base64(18),
          public_key_type: "rsa",
          public_key_encrypted: SS::Crypto.encrypt(key.public_key.to_pem)
        )

        jwt_assertion = JSON::JWT.new(
          # issuer
          iss: application.client_id,
          # subject
          sub: gws_user.uid,
          # scope
          scope: Gws::Role.permission_names.join(" "),
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

      include_context "what gws presence is"
    end

    context "with jwt bearer grant type with confidential application" do
      before do
        redirect_uri = "#{unique_url}/cb"
        application = SS::OAuth2::Application::Confidential.create!(
          name: unique_id, permissions: Gws::Role.permission_names, state: "enabled",
          client_id: SecureRandom.urlsafe_base64(18), client_secret: SecureRandom.urlsafe_base64(36),
          redirect_uris: redirect_uri
        )

        jwt_assertion = JSON::JWT.new(
          # issuer
          iss: application.client_id,
          # subject
          sub: gws_user.uid,
          # scope
          scope: Gws::Role.permission_names.join(" "),
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

      include_context "what gws presence is"
    end

    context "with implicit grant with confidential application" do
      before do
        # implicit flow の場合、まずはどうにかしてログインする
        get auth_token_path
        auth_token = JSON.parse(response.body)["auth_token"]
        params = {
          'authenticity_token' => auth_token,
          'item[email]' => gws_user.email,
          'item[password]' => "pass"
        }
        post sns_login_path(format: :json), params: params

        # access_token を要求する
        redirect_uri = "#{unique_url}/cb"
        application = SS::OAuth2::Application::Confidential.create!(
          name: unique_id, permissions: Gws::Role.permission_names, state: "enabled",
          client_id: SecureRandom.urlsafe_base64(18), client_secret: SecureRandom.urlsafe_base64(36),
          redirect_uris: redirect_uri
        )

        state = SecureRandom.hex(16)
        token_params = {
          response_type: "token",
          client_id: application.client_id,
          redirect_uri: redirect_uri,
          scope: Gws::Role.permission_names.join(" "),
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

      include_context "what gws presence is"
    end

    context "with authorization code grant with confidential application" do
      before do
        # authorization code flow の場合、まずはどうにかしてログインする
        get auth_token_path
        auth_token = JSON.parse(response.body)["auth_token"]
        params = {
          'authenticity_token' => auth_token,
          'item[email]' => gws_user.email,
          'item[password]' => "pass"
        }
        post sns_login_path(format: :json), params: params

        # access_token を要求する
        redirect_uri = "#{unique_url}/cb"
        application = SS::OAuth2::Application::Confidential.create!(
          name: unique_id, permissions: Gws::Role.permission_names, state: "enabled",
          client_id: SecureRandom.urlsafe_base64(18), client_secret: SecureRandom.urlsafe_base64(36),
          redirect_uris: redirect_uri
        )

        state = SecureRandom.hex(16)
        code_params = {
          response_type: "code",
          client_id: application.client_id,
          redirect_uri: redirect_uri,
          scope: Gws::Role.permission_names.join(" "),
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

      include_context "what gws presence is"
    end
  end
end
