require 'spec_helper'

describe Member::Agents::Nodes::LoginController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let(:client_id) { unique_id }
  let(:client_secret) { unique_id }

  context "twitter" do
    let!(:node) do
      create :member_node_login, layout: layout, redirect_url: "/#{unique_id}/",
        twitter_oauth: "enabled", twitter_client_id: client_id, twitter_client_secret: client_secret
    end
    let(:code) { unique_id }
    let(:token) { unique_id }
    let(:token_secret) { unique_id }
    let(:twitter_id) { rand(100..999) }
    let(:twitter_name) { unique_id }
    let(:twitter_screen_name) { unique_id }
    let(:twitter_email) { unique_email }

    before do
      # WebMock.disable_net_connect!
      WebMock.reset!

      stub_request(:post, "https://api.twitter.com/oauth/request_token").to_return do |request|
        # puts request.headers["Authorization"]
        expect(request.headers["Authorization"]).to start_with("OAuth ")
        callback = "#{node.full_url}twitter/callback"
        callback = URI.encode_www_form_component(callback)
        expect(request.headers["Authorization"]).to include "oauth_callback=\"#{callback}\""
        expect(request.headers["Authorization"]).to include "oauth_consumer_key=\"#{client_id}\""
        expect(request.url_encoded?).to be_truthy
        expect(request.body).to be_blank

        body = {
          oauth_token: token,
          # oauth_token_secret: token_secret,
          oauth_callback_confirmed: true
        }
        { status: 200, headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }, body: body.to_query }
      end
      stub_request(:post, "https://api.twitter.com/oauth/access_token").to_return do |request|
        # puts request.headers["Authorization"]
        expect(request.headers["Authorization"]).to start_with("OAuth ")
        expect(request.headers["Authorization"]).to include "oauth_consumer_key=\"#{client_id}\""
        expect(request.headers["Authorization"]).to include "oauth_token=\"#{token}\""
        expect(request.url_encoded?).to be_falsey
        expect(request.body).to be_blank

        body = {
          oauth_token: token,
          oauth_token_secret: token_secret,
          user_id: twitter_id,
          screen_name: twitter_name,
        }
        { status: 200, headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }, body: body.to_query }
      end
      stub_request(:get, /#{::Regexp.escape("https://api.twitter.com/1.1/account/verify_credentials.json")}/).to_return do |request|
        # puts request.headers["Authorization"]
        expect(request.headers["Authorization"]).to start_with("OAuth ")
        expect(request.headers["Authorization"]).to include "oauth_consumer_key=\"#{client_id}\""
        expect(request.headers["Authorization"]).to include "oauth_token=\"#{token}\""
        expect(request.body).to be_blank
        expect(request.uri.query_values["include_email"]).to eq "true"

        body = {
          description: unique_id,
          id: twitter_id,
          id_str: twitter_id.to_s,
          name: twitter_name,
          screen_name: twitter_screen_name,
          email: twitter_email
        }
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
      end
    end

    after do
      WebMock.reset!
    end

    it do
      post "#{node.full_url}twitter"
      expect(response.status).to eq 302
      expect(response.location).to be_present
      location = ::Addressable::URI.parse(response.location)
      expect(location.origin).to eq "https://api.twitter.com"
      expect(location.query).to be_present
      query_values = location.query_values
      expect(query_values["oauth_token"]).to eq token

      get "#{node.full_url}twitter/callback?#{{state: query_values["state"], code: code}.to_query}"
      expect(response.status).to eq 302
      location = ::Addressable::URI.parse(response.location)
      expect(location.origin).to eq site.full_url[0..-2]
      expect(location.path).to eq node.redirect_url

      expect(Cms::Member.all.count).to eq 1
      Cms::Member.all.first.tap do |member|
        expect(member.name).to eq twitter_name
      end
    end
  end
end
