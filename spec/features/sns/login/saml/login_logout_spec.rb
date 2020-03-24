require 'spec_helper'

describe "sns/login/saml", type: :feature, dbscope: :example, js: true, saml_sampling: true do
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

  context "when email is given" do
    it do
      visit sns_mypage_path
      click_on name

      #
      # blow form is outside of SHIRASAGI. it's sampling (https://capriza.github.io/samling/samling.html)
      #
      within "form#samlProps" do
        fill_in "nameIdentifier", with: sys_user.email
        click_on "Next"
      end

      within "form#samlResponseForm" do
        click_on "Post Response!"
      end

      #
      # Now back to SHIRASAGI
      #

      # confirm a user has been logged-in
      expect(page).to have_css(".main-navi", text: I18n.t("sns.account"))

      # do logout
      within "nav.user" do
        find("span.name").click
        click_on I18n.t("ss.logout")
      end

      # confirm a login form has been shown
      expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
      expect(page).to have_css("li", text: name)
    end
  end

  context "when uid is given" do
    before do
      user = sys_user
      user.uid = unique_id
      user.save!
    end

    it do
      visit sns_mypage_path
      click_on name

      #
      # blow form is outside of SHIRASAGI. it's sampling (https://capriza.github.io/samling/samling.html)
      #
      within "form#samlProps" do
        fill_in "nameIdentifier", with: sys_user.uid
        click_on "Next"
      end

      within "form#samlResponseForm" do
        click_on "Post Response!"
      end

      #
      # Now back to SHIRASAGI
      #

      # confirm a user has been logged-in
      expect(page).to have_css(".main-navi", text: I18n.t("sns.account"))

      # do logout
      within "nav.user" do
        find("span.name").click
        click_on I18n.t("ss.logout")
      end

      # confirm a login form has been shown
      expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
      expect(page).to have_css("li", text: name)
    end
  end

  context "when 'urn:oasis:names:tc:SAML:2.0:status:AuthnFailed' is responded" do
    let(:status_code) { "urn:oasis:names:tc:SAML:2.0:status:AuthnFailed" }
    let(:status_message) { "Authentication Failed" }

    it do
      visit sns_mypage_path
      click_on name

      #
      # blow form is outside of SHIRASAGI. it's sampling (https://capriza.github.io/samling/samling.html)
      #
      within "form#samlProps" do
        fill_in "nameIdentifier", with: sys_user.email
        fill_in "samlStatusCode", with: status_code
        fill_in "samlStatusMessage", with: status_message
        click_on "Next"
      end

      within "form#samlResponseForm" do
        click_on "Post Response!"
      end

      #
      # Now back to SHIRASAGI
      #

      # confirm a error message is shown
      expect(page).to have_css(".error-message", text: status_message)
    end
  end

  context "when unregistered user is responded (this means authentication was succeeded but authorization was failed)" do
    it do
      visit sns_mypage_path
      click_on name

      #
      # blow form is outside of SHIRASAGI. it's sampling (https://capriza.github.io/samling/samling.html)
      #
      within "form#samlProps" do
        fill_in "nameIdentifier", with: unique_id
        click_on "Next"
      end

      within "form#samlResponseForm" do
        click_on "Post Response!"
      end

      #
      # Now back to SHIRASAGI
      #

      # confirm a error message is shown
      expect(page).to have_css(".error-message", text: I18n.t("sns.errors.invalid_login"))
    end
  end

  context "when ready state is expired" do
    let(:now) { Time.zone.now.beginning_of_minute }

    it do
      Timecop.freeze(now) do
        visit sns_mypage_path
        click_on name
      end

      Timecop.freeze(now + 10.minutes + 1.second) do
        #
        # blow form is outside of SHIRASAGI. it's sampling (https://capriza.github.io/samling/samling.html)
        #
        within "form#samlProps" do
          fill_in "nameIdentifier", with: sys_user.email
          click_on "Next"
        end

        within "form#samlResponseForm" do
          click_on "Post Response!"
        end
      end

      #
      # Now back to SHIRASAGI
      #

      # confirm 404 error is shown
      expect(page).to have_content("404")
    end
  end

  context "when user directly log in to gws" do
    it do
      # ensure that sys_user is created before gws_site is created
      sys_user
      visit gws_portal_path(site: gws_site)
      expect(page).to have_css("#page-login")
      click_on name

      #
      # blow form is outside of SHIRASAGI. it's sampling (https://capriza.github.io/samling/samling.html)
      #
      within "form#samlProps" do
        fill_in "nameIdentifier", with: sys_user.email
        click_on "Next"
      end

      within "form#samlResponseForm" do
        click_on "Post Response!"
      end

      #
      # Now back to SHIRASAGI
      #

      # confirm a user has been logged-in
      expect(page).to have_css("nav.user .name", text: sys_user.name)
      # confirm gws_portal is shown to user
      expect(page).to have_css("#head .application-menu .gws .current", text: I18n.t('ss.links.gws'))
    end
  end
end
