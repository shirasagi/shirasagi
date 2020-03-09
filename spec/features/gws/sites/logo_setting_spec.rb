require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, tmpdir: true, js: true do
  let(:site) { gws_site }
  let(:logo_application_name) { unique_id }

  before { login_gws_user }

  context "when image and text is given" do
    it do
      visit gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      # open addon
      first("#addon-gws-agents-addons-system-logo_setting .addon-head h2").click

      # fill form
      within "#addon-gws-agents-addons-system-logo_setting" do
        fill_in "item[logo_application_name]", with: logo_application_name
        # click_on I18n.t("ss.buttons.upload")
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t("ss.buttons.attach")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.logo_application_name).to eq logo_application_name
      expect(site.logo_application_image).to be_present

      # check that logs is appeared on portal
      visit gws_portal_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_css("img[alt='#{logo_application_name}']")
      end

      # check that logs is appeared on login form
      visit gws_login_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_css("img[alt='#{logo_application_name}']")
      end
    end
  end

  context "when only text is given" do
    it do
      visit gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      # open addon
      first("#addon-gws-agents-addons-system-logo_setting .addon-head h2").click

      # fill form
      within "#addon-gws-agents-addons-system-logo_setting" do
        fill_in "item[logo_application_name]", with: logo_application_name
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.logo_application_name).to eq logo_application_name
      expect(site.logo_application_image).to be_blank

      # check that logs is appeared on portal
      visit gws_portal_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_no_css("img")
        expect(page).to have_css(".ss-logo-application-name", text: logo_application_name)
      end

      # check that logs is appeared on login form
      visit gws_login_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_no_css("img")
        expect(page).to have_css(".ss-logo-application-name", text: logo_application_name)
      end
    end
  end
end
