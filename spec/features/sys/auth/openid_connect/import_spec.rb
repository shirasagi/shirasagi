require 'spec_helper'

describe "sys/auth/open_id_connects", type: :feature, dbscope: :example do
  let(:name) { unique_id }
  let(:filename) { unique_id }
  let(:client_id) { unique_id }
  let(:client_secret) { unique_id }

  before { login_sys_user }

  context "with sample discovery json" do
    let(:discovery_file) { "#{Rails.root}/spec/fixtures/sys/auth/discovery-1.json" }

    it do
      visit sys_auth_open_id_connects_path
      click_on I18n.t("sys.links.new_from_discovery")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[filename]", with: filename

        fill_in "item[client_id]", with: client_id
        fill_in "item[in_client_secret]", with: client_secret
        attach_file "item[in_discovery_file]", discovery_file

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Sys::Auth::OpenIdConnect.count).to eq 1
      Sys::Auth::OpenIdConnect.first.tap do |item|
        expect(item.name).to eq name
        expect(item.filename).to eq filename

        expect(item.client_id).to eq client_id
        expect(item.client_secret).to eq SS::Crypt.encrypt(client_secret)

        expect(item.issuer).to eq "https://example.com/"
        expect(item.auth_url).to eq "https://example.com/authorize"
        expect(item.token_url).to eq "https://example.com/token"
        expect(item.response_type).to eq "id_token"
        expect(item.scopes).to eq %w(pets_read pets_write admin)
        expect(item.max_age).to be_nil
        expect(item.claims).to eq %w(email sub)
        expect(item.response_mode).to be_blank
        expect(item.jwks_uri).to eq "https://example.com/.well-known/jwks.json"
      end
    end
  end

  context "with google discovery json" do
    # downloaded from "https://accounts.google.com/.well-known/openid-configuration"
    let(:discovery_file) { "#{Rails.root}/spec/fixtures/sys/auth/discovery-google.json" }

    it do
      visit sys_auth_open_id_connects_path
      click_on I18n.t("sys.links.new_from_discovery")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[filename]", with: filename

        fill_in "item[client_id]", with: client_id
        fill_in "item[in_client_secret]", with: client_secret
        attach_file "item[in_discovery_file]", discovery_file

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Sys::Auth::OpenIdConnect.count).to eq 1
      Sys::Auth::OpenIdConnect.first.tap do |item|
        expect(item.name).to eq name
        expect(item.filename).to eq filename

        expect(item.client_id).to eq client_id
        expect(item.client_secret).to eq SS::Crypt.encrypt(client_secret)

        expect(item.issuer).to eq "https://accounts.google.com"
        expect(item.auth_url).to eq "https://accounts.google.com/o/oauth2/v2/auth"
        expect(item.token_url).to eq "https://oauth2.googleapis.com/token"
        expect(item.response_type).to eq "id_token"
        expect(item.scopes).to eq %w(openid email profile)
        expect(item.max_age).to be_blank
        expect(item.claims).to eq %w(email sub)
        expect(item.response_mode).to be_blank
        expect(item.jwks_uri).to eq "https://www.googleapis.com/oauth2/v3/certs"
      end
    end
  end
end
