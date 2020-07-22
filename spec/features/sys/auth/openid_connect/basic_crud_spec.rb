require 'spec_helper'

describe "sys/auth/open_id_connects", type: :feature, dbscope: :example do
  let(:name) { unique_id }
  let(:filename) { unique_id }
  let(:client_id) { unique_id }
  let(:client_id2) { unique_id }
  let(:client_secret) { unique_id }
  let(:issuer) { "http://#{unique_id}.example.jp/sso" }
  let(:auth_url) { "http://#{unique_id}.example.jp/sso" }
  let(:token_url) { "http://#{unique_id}.example.jp/sso" }
  let(:response_type) { unique_id }
  let(:scopes) { [ "openid", "email", unique_id ] }
  let(:max_age) { rand(10..100) }
  let(:claims) { [ "email", "sub", unique_id ] }
  let(:response_mode) { unique_id }
  let(:jwks_uri) { "http://#{unique_id}.example.jp/jwks" }

  before { login_sys_user }

  it do
    #
    # Create
    #
    visit sys_auth_open_id_connects_path
    click_on I18n.t("ss.links.new")

    within "form#item-form" do
      fill_in "item[name]", with: name
      fill_in "item[filename]", with: filename

      fill_in "item[client_id]", with: client_id
      fill_in "item[in_client_secret]", with: client_secret
      fill_in "item[issuer]", with: issuer
      fill_in "item[auth_url]", with: auth_url
      fill_in "item[token_url]", with: token_url
      fill_in "item[response_type]", with: response_type
      fill_in "item[scopes]", with: scopes.join(" ")
      fill_in "item[max_age]", with: max_age
      fill_in "item[claims]", with: claims.join(" ")
      fill_in "item[response_mode]", with: response_mode
      fill_in "item[jwks_uri]", with: jwks_uri

      click_on I18n.t("ss.buttons.save")
    end
    expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

    expect(Sys::Auth::OpenIdConnect.count).to eq 1
    Sys::Auth::OpenIdConnect.first.tap do |item|
      expect(item.name).to eq name
      expect(item.filename).to eq filename

      expect(item.client_id).to eq client_id
      expect(item.client_secret).to eq SS::Crypt.encrypt(client_secret)
      expect(item.issuer).to eq issuer
      expect(item.auth_url).to eq auth_url
      expect(item.token_url).to eq token_url
      expect(item.response_type).to eq response_type
      expect(item.scopes).to eq scopes
      expect(item.max_age).to eq max_age
      expect(item.claims).to eq claims
      expect(item.response_mode).to eq response_mode
      expect(item.jwks_uri).to eq jwks_uri
    end

    #
    # Update
    #
    visit sys_auth_open_id_connects_path
    click_on name
    click_on I18n.t("ss.links.edit")

    within "form#item-form" do
      fill_in "item[client_id]", with: client_id2

      click_on I18n.t("ss.buttons.save")
    end
    expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

    expect(Sys::Auth::OpenIdConnect.count).to eq 1
    Sys::Auth::OpenIdConnect.first.tap do |item|
      expect(item.name).to eq name
      expect(item.filename).to eq filename

      expect(item.client_id).to eq client_id2
      expect(item.client_secret).to eq SS::Crypt.encrypt(client_secret)
      expect(item.issuer).to eq issuer
      expect(item.auth_url).to eq auth_url
      expect(item.token_url).to eq token_url
      expect(item.response_type).to eq response_type
      expect(item.scopes).to eq scopes
      expect(item.max_age).to eq max_age
      expect(item.claims).to eq claims
      expect(item.response_mode).to eq response_mode
      expect(item.jwks_uri).to eq jwks_uri
    end

    #
    # Delete
    #
    visit sys_auth_open_id_connects_path
    click_on name
    click_on I18n.t("ss.links.delete")
    within "form" do
      click_on I18n.t("ss.buttons.delete")
    end
    expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

    expect(Sys::Auth::OpenIdConnect.count).to eq 0
  end
end
