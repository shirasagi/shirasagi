require 'spec_helper'

describe "Member::Agents::Nodes::LoginController", type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let(:client_id) { unique_id }
  let(:client_secret) { unique_id }
  let!(:node) do
    create :member_node_login, layout: layout, redirect_url: "/#{unique_id}/",
      twitter2_oauth: "enabled", twitter2_client_id: client_id, twitter2_client_secret: client_secret
  end
  let(:code) { unique_id }
  let(:access_token) { unique_id }
  let(:twitter_id) { rand(100..999) }
  let(:twitter_name) { unique_id }
  let(:twitter_username) { unique_id }

  before do
    # WebMock.disable_net_connect!
    WebMock.reset!

    stub_request(:post, "https://api.twitter.com/2/oauth2/token").to_return do |request|
      body = {
        token_type: "bearer",
        expires_in: 7200,
        access_token: access_token,
        scope: "public"
      }
      { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
    end
    stub_request(:get, /#{::Regexp.escape("https://api.twitter.com/2/users/me")}/).to_return do |request|
      body = {
        data: {
          id: twitter_id,
          name: twitter_name,
          username: twitter_username,
        }
      }
      { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
    end
  end

  after do
    WebMock.reset!
  end

  it do
    post "#{node.full_url}twitter2"
    expect(response.status).to eq 302
    expect(response.location).to be_present
    location = ::Addressable::URI.parse(response.location)
    expect(location.origin).to eq "https://twitter.com"
    expect(location.query).to be_present
    query_values = location.query_values
    expect(query_values["client_id"]).to eq client_id
    expect(query_values["redirect_uri"]).to eq "#{node.full_url}twitter2/callback"

    get "#{node.full_url}twitter2/callback?#{{state: query_values["state"], code: code}.to_query}"
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
