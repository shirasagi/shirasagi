require 'spec_helper'

describe 'gws_notice_readables', type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let(:minimum_permissions) do
    %w(
      read_private_gws_notices
      read_other_gws_notices
      read_private_gws_notice_folders
      read_other_gws_notice_folders
      read_private_gws_notice_categories
      read_other_gws_notice_categories
    )
  end
  let!(:role) { create :gws_role, cur_site: site, permissions: minimum_permissions }
  let!(:user) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ role.id ] }

  let!(:folder) { create :gws_notice_folder, cur_site: site }
  let!(:file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: user) }
  let!(:item) do
    create(
      :gws_notice_post, cur_site: site, cur_user: user, folder: folder, file_ids: [ file.id ],
      readable_setting_range: "public", state: "public"
    )
  end

  shared_examples "what gws_notice_readables is" do
    it do
      get gws_notice_readables_path(site: site, folder_id: "-", category_id: "-", format: :json), headers: @headers
      expect(response.status).to eq 200
      JSON.parse(response.body).tap do |json|
        expect(json).to be_a(Array)
        json[0].tap do |item_json|
          expect(item_json).to be_a(Hash)
          expect(item_json["_id"]).to eq item.id
          expect(item_json["name"]).to eq item.name
          expect(item_json["text"]).to eq item.text
          expect(item_json["file_ids"]).to eq [ file.id ]
          expect(item_json["files"]).to be_a(Hash)
          item_json["files"][file.id.to_s].tap do |file_json|
            expect(file_json["name"]).to eq file.name
            expect(file_json["filename"]).to eq file.filename
            expect(file_json["url"]).to eq "http://www.example.com#{file.url}"
          end
        end
      end

      get file.url, headers: @headers
      expect(response.status).to eq 200
      expect(response.headers["Content-Type"]).to eq file.content_type
      expect(response.headers["Content-Length"].to_i).to eq file.size
      # expect(response.headers["Last-Modified"].in_time_zone).to eq file.updated.in_time_zone.change(usec: 0)
      expect(Digest::MD5.hexdigest(response.body)).to eq Digest::MD5.file(file.path).to_s
    end
  end

  context "with login form" do
    before do
      # get and save  auth token
      get sns_auth_token_path(format: :json)
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

    include_context "what gws_notice_readables is"
  end

  context "with token auth" do
    context "with jwt bearer grant type with service application" do
      before do
        key = OpenSSL::PKey::RSA.generate(2048)

        application = SS::OAuth2::Application::Service.create!(
          name: unique_id, permissions: minimum_permissions, state: "enabled",
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
          scope: minimum_permissions.join(" "),
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

      include_context "what gws_notice_readables is"
    end

    context "with jwt bearer grant type with confidential application" do
      before do
        redirect_uri = "#{unique_url}/cb"
        application = SS::OAuth2::Application::Confidential.create!(
          name: unique_id, permissions: minimum_permissions, state: "enabled",
          client_id: SecureRandom.urlsafe_base64(18), client_secret: SecureRandom.urlsafe_base64(36),
          redirect_uris: redirect_uri
        )

        jwt_assertion = JSON::JWT.new(
          # issuer
          iss: application.client_id,
          # subject
          sub: user.uid,
          # scope
          scope: minimum_permissions.join(" "),
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
        expect(response.status).to eq 200

        json = JSON.parse(response.body)
        @headers = {
          "Authorization" => "Bearer #{json["access_token"]}"
        }
      end

      include_context "what gws_notice_readables is"
    end

    context "with implicit grant with confidential application" do
      before do
        # implicit flow の場合、まずはどうにかしてログインする
        get sns_auth_token_path(format: :json)
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

      include_context "what gws_notice_readables is"
    end

    context "with authorization code grant with confidential application" do
      before do
        # authorization code flow の場合、まずはどうにかしてログインする
        get sns_auth_token_path(format: :json)
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

      include_context "what gws_notice_readables is"
    end
  end
end
