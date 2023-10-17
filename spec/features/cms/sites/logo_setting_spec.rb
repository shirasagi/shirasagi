require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:logo_application_name) { unique_id }

  context "when image and text is given" do
    context "basic crud" do
      before { login_cms_user }

      it do
        visit cms_site_path(site: site)
        click_on I18n.t("ss.links.edit")

        # open addon
        ensure_addon_opened("#addon-ss-agents-addons-logo_setting")

        # fill form
        within "#addon-ss-agents-addons-logo_setting" do
          fill_in "item[logo_application_name]", with: logo_application_name
          wait_cbox_open do
            # click_on I18n.t("ss.buttons.upload")
            first(".btn-file-upload").click
          end
        end
        wait_for_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          wait_cbox_close { click_on I18n.t("ss.buttons.attach") }
        end
        within "form#item-form" do
          expect(page).to have_css(".ss-file-field", text: "keyvisual")
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

          info = image_element_info(first("img[alt='#{logo_application_name}']"))
          expect(info[:naturalWidth]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_WIDTH
          expect(info[:naturalHeight]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_HEIGHT
        end
      end
    end

    context "basic crud" do
      let(:domain) { unique_domain }

      before do
        site.logo_application_name = logo_application_name
        site.logo_application_image = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
        if [ 0, 1 ].sample == 0
          site.domains = [ domain ]
        else
          site.mypage_domain = domain
        end
        site.save!

        SS::Application.request_interceptor = proc do |env|
          env["HTTP_X_FORWARDED_HOST"] = domain
        end
      end

      after do
        SS::Application.request_interceptor = nil
      end

      it do
        # check that the logo is appeared on login form
        visit cms_login_path(site: site)
        within ".ss-logo-wrap" do
          expect(page).to have_css("img[alt='#{logo_application_name}']")

          info = image_element_info(first("img[alt='#{logo_application_name}']"))
          expect(info[:naturalWidth]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_WIDTH
          expect(info[:naturalHeight]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_HEIGHT
        end
      end
    end
  end

  context "when only text is given" do
    before { login_cms_user }

    it do
      visit cms_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      # open addon
      ensure_addon_opened("#addon-ss-agents-addons-logo_setting")

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
