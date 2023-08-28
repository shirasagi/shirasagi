require 'spec_helper'

describe "sys/auth/saml", type: :feature, dbscope: :example do
  let(:name) { unique_id }
  let(:filename) { unique_id }
  let(:entity_id) { unique_id }
  let(:entity_id2) { unique_id }
  let(:sso_url) { "http://#{unique_id}.example.jp/sso" }
  let(:x509_file) { "#{Rails.root}/spec/fixtures/sys/auth/x509-512b-rsa-example-cert.der" }
  let(:force_authn_state) { %w(disabled enabled).sample }
  let(:force_authn_state_label) { I18n.t("sys.options.force_authn_state.#{force_authn_state}") }

  before { login_sys_user }

  it do
    #
    # Create
    #
    visit sys_auth_samls_path
    click_on I18n.t("ss.links.new")

    within "form#item-form" do
      fill_in "item[name]", with: name
      fill_in "item[filename]", with: filename
      fill_in "item[entity_id]", with: entity_id
      fill_in "item[sso_url]", with: sso_url
      attach_file "item[in_x509_cert]", x509_file
      select force_authn_state_label, from: "item[force_authn_state]"

      click_on I18n.t("ss.buttons.save")
    end
    expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

    expect(Sys::Auth::Saml.count).to eq 1
    Sys::Auth::Saml.first.tap do |item|
      expect(item.name).to eq name
      expect(item.filename).to eq filename
      expect(item.entity_id).to eq entity_id
      expect(item.sso_url).to eq sso_url
      expect(item.force_authn_state).to eq force_authn_state
      expect(SS::Crypto.decrypt(item.x509_cert)).not_to be_nil
    end

    #
    # Update
    #
    visit sys_auth_samls_path
    click_on name
    click_on I18n.t("ss.links.edit")

    within "form#item-form" do
      fill_in "item[entity_id]", with: entity_id2

      click_on I18n.t("ss.buttons.save")
    end
    expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

    expect(Sys::Auth::Saml.count).to eq 1
    Sys::Auth::Saml.first.tap do |item|
      expect(item.name).to eq name
      expect(item.filename).to eq filename
      expect(item.entity_id).to eq entity_id2
      expect(item.sso_url).to eq sso_url
      expect(item.force_authn_state).to eq force_authn_state
      expect(SS::Crypto.decrypt(item.x509_cert)).not_to be_nil
    end

    #
    # Delete
    #
    visit sys_auth_samls_path
    click_on name
    within ".nav-menu" do
      click_on I18n.t("ss.links.delete")
    end
    within "form" do
      click_on I18n.t("ss.buttons.delete")
    end
    expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

    expect(Sys::Auth::Saml.count).to eq 0
  end
end
