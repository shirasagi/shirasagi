require 'spec_helper'

describe Member::Agents::Nodes::LoginController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let(:client_id) { unique_id }
  let(:client_secret) { unique_id }
  let(:code) { unique_id }

  context "yahoojp_v2" do
    let!(:node) do
      create :member_node_login, layout: layout, redirect_url: "/#{unique_id}/",
        yahoojp_v2_oauth: "enabled", yahoojp_v2_client_id: client_id, yahoojp_v2_client_secret: client_secret
    end
    let(:access_token) { unique_id }
    let(:yahoojp_sub) { rand(100..999) }
    let(:yahoojp_name) { unique_id }
    let(:yahoojp_given_name) { unique_id }
    let(:yahoojp_family_name) { unique_id }
    let(:yahoojp_nickname) { unique_id }
    let(:yahoojp_picture_url) { unique_url }
    let(:yahoojp_email) { unique_email }

    before do
      # WebMock.disable_net_connect!
      WebMock.reset!

      stub_request(:post, "https://auth.login.yahoo.co.jp/yconnect/v2/token").to_return do |request|
        expect(request.headers["Authorization"]).to eq "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
        expect(request.url_encoded?).to be_truthy
        params = URI.decode_www_form(request.body)
        code_params = params.select { |k, _v| k == "code" }.map { |_k, v| v }
        expect(code_params).to eq [ code ]
        grant_type_params = params.select { |k, _v| k == "grant_type" }.map { |_k, v| v }
        expect(grant_type_params).to eq %w(authorization_code)
        redirect_uri_params = params.select { |k, _v| k == "redirect_uri" }.map { |_k, v| v }
        expect(redirect_uri_params).to eq [ "#{node.full_url}yahoojp_v2/callback" ]

        body = {
          token_type: "bearer",
          expires_in: 7200,
          access_token: access_token,
          scope: %w(openid profile email address).join(" ")
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
      stub_request(:get, "https://userinfo.yahooapis.jp/yconnect/v2/attribute").to_return do |request|
        expect(request.headers["Authorization"]).to eq "Bearer #{access_token}"
        expect(request.body).to be_blank

        body = {
          sub: yahoojp_sub,
          name: yahoojp_name,
          given_name: yahoojp_given_name,
          family_name: yahoojp_family_name,
          nickname: yahoojp_nickname,
          picture: yahoojp_picture_url,
          email: yahoojp_email,
          email_verified: true,
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
    end

    after do
      WebMock.reset!
    end

    it do
      post "#{node.full_url}yahoojp_v2"
      expect(response.status).to eq 302
      expect(response.location).to be_present
      location = Addressable::URI.parse(response.location)
      expect(location.origin).to eq "https://auth.login.yahoo.co.jp"
      expect(location.query).to be_present
      query_values = location.query_values
      expect(query_values["client_id"]).to eq client_id
      expect(query_values["redirect_uri"]).to eq "#{node.full_url}yahoojp_v2/callback"
      expect(query_values["response_type"]).to eq "code"
      expect(query_values["scope"]).to eq %w(openid profile email address).join(" ")
      expect(query_values["state"]).to be_present

      get "#{node.full_url}yahoojp_v2/callback?#{{state: query_values["state"], code: code}.to_query}"
      expect(response.status).to eq 302
      location = Addressable::URI.parse(response.location)
      expect(location.origin).to eq site.full_url[0..-2]
      expect(location.path).to eq node.redirect_url

      expect(Cms::Member.all.count).to eq 1
      Cms::Member.all.first.tap do |member|
        expect(member.name).to eq yahoojp_name
      end
    end
  end
end
