require 'spec_helper'

describe Member::Agents::Nodes::LoginController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let(:client_id) { unique_id }
  let(:client_secret) { unique_id }
  let(:code) { unique_id }

  context "google_oauth2" do
    let!(:node) do
      create :member_node_login, layout: layout, redirect_url: "/#{unique_id}/",
        google_oauth2_oauth: "enabled", google_oauth2_client_id: client_id, google_oauth2_client_secret: client_secret
    end
    let(:access_token) { unique_id }
    let(:refresh_token) { unique_id }
    let(:scopes) do
      %w(
        https://www.googleapis.com/auth/userinfo.email
        https://www.googleapis.com/auth/userinfo.profile
        https://www.googleapis.com/auth/plus.me)
    end
    let(:google_oauth2_azp) { unique_id }
    let(:google_oauth2_aud) { unique_id }
    let(:google_oauth2_sub) { unique_id }
    let(:google_oauth2_exp) { rand(100..999) }
    let(:google_oauth2_expires_in) { rand(100..999) }
    let(:google_oauth2_email) { unique_email }
    let(:google_oauth2_name) { unique_id }
    let(:google_oauth2_given_name) { unique_id }
    let(:google_oauth2_last_name) { unique_id }
    let(:google_oauth2_image_url) { unique_url }

    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
      WebMock.reset!

      stub_request(:post, "https://oauth2.googleapis.com/token").to_return do |request|
        expect(request.headers["Authorization"]).to eq "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
        expect(request.url_encoded?).to be_truthy
        params = URI.decode_www_form(request.body)
        code_params = params.select { |k, _v| k == "code" }.map { |_k, v| v }
        expect(code_params).to eq [ code ]
        grant_type_params = params.select { |k, _v| k == "grant_type" }.map { |_k, v| v }
        expect(grant_type_params).to eq %w(authorization_code)
        redirect_uri_params = params.select { |k, _v| k == "redirect_uri" }.map { |_k, v| v }
        expect(redirect_uri_params).to eq [ "#{node.full_url}google_oauth2/callback" ]

        body = {
          token_type: "bearer",
          scope: scopes.join(" "),
          expires_in: 7200,
          access_token: access_token,
          refresh_token: refresh_token,
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
      stub_request(:post, /#{::Regexp.escape("https://www.googleapis.com/oauth2/v3/tokeninfo")}/).to_return do |request|
        expect(request.headers["Authorization"]).to be_blank
        expect(request.body).to eq "access_token=#{access_token}"
        expect(request.uri.query_values).to be_blank

        body = {
          azp: google_oauth2_azp,
          aud: google_oauth2_aud,
          sub: google_oauth2_sub,
          scope: scopes.join(" "),
          exp: google_oauth2_exp,
          expires_in: google_oauth2_expires_in,
          email: google_oauth2_email,
          email_verified: true,
          access_type: "offline"
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
      stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo").to_return do |request|
        expect(request.headers["Authorization"]).to eq "Bearer #{access_token}"
        expect(request.body).to be_blank

        body = {
          name: google_oauth2_name,
          email: google_oauth2_email,
          email_verified: true,
          given_name: google_oauth2_given_name,
          last_name: google_oauth2_last_name,
          image: google_oauth2_image_url,
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    it do
      post "#{node.full_url}google_oauth2"
      expect(response.status).to eq 302
      expect(response.location).to be_present
      location = ::Addressable::URI.parse(response.location)
      expect(location.origin).to eq "https://accounts.google.com"
      expect(location.query).to be_present
      query_values = location.query_values
      expect(query_values["client_id"]).to eq client_id
      expect(query_values["redirect_uri"]).to eq "#{node.full_url}google_oauth2/callback"
      expect(query_values["response_type"]).to eq "code"
      expect(query_values["scope"]).to eq scopes.join(" ")
      expect(query_values["state"]).to be_present

      get "#{node.full_url}google_oauth2/callback?#{{state: query_values["state"], code: code}.to_query}"
      expect(response.status).to eq 302
      location = ::Addressable::URI.parse(response.location)
      expect(location.origin).to eq site.full_url[0..-2]
      expect(location.path).to eq node.redirect_url

      expect(Cms::Member.all.count).to eq 1
      Cms::Member.all.first.tap do |member|
        expect(member.name).to eq google_oauth2_name
      end
    end
  end
end
