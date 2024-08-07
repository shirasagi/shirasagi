require 'spec_helper'

describe Member::Agents::Nodes::LoginController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let(:client_id) { unique_id }
  let(:client_secret) { unique_id }
  let(:code) { unique_id }

  context "github" do
    let!(:node) do
      create :member_node_login, layout: layout, redirect_url: "/#{unique_id}/",
        github_oauth: "enabled", github_client_id: client_id, github_client_secret: client_secret
    end
    let(:access_token) { unique_id }
    let(:github_id) { rand(100..999) }
    let(:github_login) { unique_id }
    let(:github_name) { unique_id }
    let(:github_avatar_url) { unique_url }
    let(:github_email) { unique_email }

    before do
      # WebMock.disable_net_connect!
      WebMock.reset!

      stub_request(:post, "https://github.com/login/oauth/access_token").to_return do |request|
        expect(request.headers["Authorization"]).to eq "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
        expect(request.url_encoded?).to be_truthy
        params = URI.decode_www_form(request.body)
        code_params = params.select { |k, _v| k == "code" }.map { |_k, v| v }
        expect(code_params).to eq [ code ]
        grant_type_params = params.select { |k, _v| k == "grant_type" }.map { |_k, v| v }
        expect(grant_type_params).to eq %w(authorization_code)
        redirect_uri_params = params.select { |k, _v| k == "redirect_uri" }.map { |_k, v| v }
        expect(redirect_uri_params).to eq [ "#{node.full_url}github/callback" ]

        body = {
          token_type: "bearer",
          expires_in: 7200,
          access_token: access_token
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
      stub_request(:get, "https://api.github.com/user").to_return do |request|
        expect(request.headers["Authorization"]).to eq "Bearer #{access_token}"
        expect(request.body).to be_blank

        body = {
          id: github_id,
          login: github_login,
          name: github_name,
          avatar_url: github_avatar_url,
          email: github_email,
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
    end

    after do
      WebMock.reset!
    end

    it do
      post "#{node.full_url}github"
      expect(response.status).to eq 302
      expect(response.location).to be_present
      location = ::Addressable::URI.parse(response.location)
      expect(location.origin).to eq "https://github.com"
      expect(location.query).to be_present
      query_values = location.query_values
      expect(query_values["client_id"]).to eq client_id
      expect(query_values["redirect_uri"]).to eq "#{node.full_url}github/callback"
      expect(query_values["response_type"]).to eq "code"
      expect(query_values["scope"]).to be_blank
      expect(query_values["state"]).to be_present

      get "#{node.full_url}github/callback?#{{state: query_values["state"], code: code}.to_query}"
      expect(response.status).to eq 302
      location = ::Addressable::URI.parse(response.location)
      expect(location.origin).to eq site.full_url[0..-2]
      expect(location.path).to eq node.redirect_url

      expect(Cms::Member.all.count).to eq 1
      Cms::Member.all.first.tap do |member|
        expect(member.name).to eq github_name
      end
    end
  end
end
