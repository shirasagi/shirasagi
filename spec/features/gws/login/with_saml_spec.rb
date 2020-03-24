require 'spec_helper'

describe "gws_login", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let(:name) { unique_id }
  let(:filename) { unique_id }
  let(:metadata_file) { "#{Rails.root}/spec/fixtures/sys/auth/metadata-1.xml" }

  before do
    Fs::UploadedFile.create_from_file(metadata_file, basename: "spec") do |file|
      saml = Sys::Auth::Saml.new
      saml.name = name
      saml.filename = filename
      saml.in_metadata = file
      saml.force_authn_state = "enabled"
      saml.save!
    end
  end

  context "with saml" do
    it do
      visit gws_login_path(site: site)
      click_on name

      #
      # blow form is outside of SHIRASAGI. it's sampling (https://capriza.github.io/samling/samling.html)
      #
      within "form#samlProps" do
        fill_in "nameIdentifier", with: user.email
        click_on "Next"
      end

      within "form#samlResponseForm" do
        click_on "Post Response!"
      end

      #
      # Now back to SHIRASAGI
      #

      # confirm a user has been logged-in
      expect(page).to have_css("nav.user .name", text: user.name)
      # confirm gws_portal is shown to user
      expect(page).to have_css("#head .application-menu .gws .current", text: I18n.t('ss.links.gws'))

      # do logout
      within "nav.user" do
        find("span.name").click
        click_on I18n.t("ss.logout")
      end

      # confirm a login form has been shown
      expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
      expect(page).to have_css("li", text: name)
      # and confirm browser back to gws_login
      expect(current_path).to eq gws_login_path(site: site)
    end
  end
end
