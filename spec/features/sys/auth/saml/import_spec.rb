require 'spec_helper'

describe "sys/auth/saml", type: :feature, dbscope: :example do
  let(:name) { unique_id }
  let(:filename) { unique_id }

  before { login_sys_user }

  context "with only public key" do
    # this is expected metadata
    let(:metadata_file) { "#{Rails.root}/spec/fixtures/sys/auth/metadata-1.xml" }
    let(:force_authn_state) { %w(disabled enabled).sample }
    let(:force_authn_state_label) { I18n.t("sys.options.force_authn_state.#{force_authn_state}") }
    let(:authn_context) { Sys::Auth::Saml::AUTHN_CONTEXT_MAP.keys.sample }
    let(:authn_context_label) { I18n.t("sys.options.authn_context.#{authn_context}") }

    it do
      visit sys_auth_samls_path
      click_on I18n.t("sys.links.new_from_metadata")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[filename]", with: filename
        attach_file "item[in_metadata]", metadata_file
        select force_authn_state_label, from: "item[force_authn_state]"
        select authn_context_label, from: "item[authn_context]"

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Sys::Auth::Saml.count).to eq 1
      Sys::Auth::Saml.first.tap do |item|
        expect(item.name).to eq name
        expect(item.filename).to eq filename
        expect(item.entity_id).not_to be_nil
        expect(item.sso_url).not_to be_nil
        expect(SS::Crypto.decrypt(item.x509_cert)).not_to be_nil
        expect(item.force_authn_state).to eq force_authn_state
        expect(item.authn_context).to eq authn_context
      end
    end
  end

  context "with private key and public key" do
    # this isn't supported metadata
    let(:metadata_file) { "#{Rails.root}/spec/fixtures/sys/auth/metadata-2.xml" }

    it do
      visit sys_auth_samls_path
      click_on I18n.t("sys.links.new_from_metadata")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[filename]", with: filename
        attach_file "item[in_metadata]", metadata_file

        click_on I18n.t("ss.buttons.save")
      end
      message = I18n.t("errors.format", attribute: Sys::Auth::Saml.t(:x509_cert), message: I18n.t("errors.messages.invalid"))
      expect(page).to have_css("#errorExplanation li", text: message)

      expect(Sys::Auth::Saml.count).to eq 0
    end
  end
end
