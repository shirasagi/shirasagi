require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, tmpdir: true, js: true do
  let(:site) { cms_site }
  let(:logo_application_name) { unique_id }

  before { login_cms_user }

  context "when image and text is given" do
    it do
      visit cms_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      # open addon
      first("#addon-ss-agents-addons-logo_setting .addon-head h2").click

      # fill form
      within "#addon-ss-agents-addons-logo_setting" do
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

      # check that logs is appeared on top
      visit cms_main_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_css("img[alt='#{logo_application_name}']")
      end

      # check that logs is appeared on login form
      visit cms_login_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_css("img[alt='#{logo_application_name}']")
      end
    end
  end

  context "when only text is given" do
    it do
      visit cms_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      # open addon
      first("#addon-ss-agents-addons-logo_setting .addon-head h2").click

      # fill form
      within "#addon-ss-agents-addons-logo_setting" do
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
      visit cms_main_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_no_css("img")
        expect(page).to have_css(".ss-logo-application-name", text: logo_application_name)
      end

      # check that logs is appeared on login form
      visit cms_login_path(site: site)
      within ".ss-logo-wrap" do
        expect(page).to have_no_css("img")
        expect(page).to have_css(".ss-logo-application-name", text: logo_application_name)
      end
    end
  end
end
