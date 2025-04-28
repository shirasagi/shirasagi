require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:logo_application_name) { unique_id }

  context "when image and text is given" do
    context "basic crud" do
      before { login_gws_user }

      it do
        visit gws_site_path(site: site)
        click_on I18n.t("ss.links.edit")

        # fill form
        within "form#item-form" do
          # open addon
          ensure_addon_opened("#addon-gws-agents-addons-system-logo_setting")

          # fill form
          within "#addon-gws-agents-addons-system-logo_setting" do
            fill_in "item[logo_application_name]", with: logo_application_name
            upload_to_ss_file_field "item[logo_application_image_id]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        site.reload
        expect(site.logo_application_name).to eq logo_application_name
        site.logo_application_image.tap do |image_file|
          # basic
          expect(image_file.model).to eq "ss/logo_file"
          expect(image_file.site_id).to be_blank
          expect(image_file.name).to eq "keyvisual.jpg"
          expect(image_file.filename).to eq "keyvisual.jpg"
          expect(image_file.size).to be > 0
          expect(image_file.content_type).to eq "image/jpeg"
          # owner item
          expect(image_file.owner_item_id).to eq site.id
          expect(image_file.owner_item_type).to eq site.class.name
          # other
          expect(image_file.user_id).to eq gws_user.id
        end

        # check that logs is appeared on portal
        visit gws_portal_path(site: site)
        within ".ss-logo-wrap" do
          expect(page).to have_css("img[alt='#{logo_application_name}']")

          info = image_element_info(first("img[alt='#{logo_application_name}']"))
          expect(info[:naturalWidth]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_WIDTH
          expect(info[:naturalHeight]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_HEIGHT
        end

        # check that logs is appeared on login form
        visit gws_login_path(site: site)
        within ".ss-logo-wrap" do
          expect(page).to have_css("img[alt='#{logo_application_name}']")

          info = image_element_info(first("img[alt='#{logo_application_name}']"))
          expect(info[:naturalWidth]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_WIDTH
          expect(info[:naturalHeight]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_HEIGHT
        end
      end
    end

    context "on login form without auth" do
      let(:domain) { unique_domain }
      let(:decorator) do
        proc do |env|
          env["HTTP_X_FORWARDED_HOST"] = domain
        end
      end

      before do
        site.logo_application_name = logo_application_name
        site.logo_application_image = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
        if [ 0, 1 ].sample == 0
          site.domains = [ domain ]
        else
          site.canonical_domain = domain
        end
        site.save!

        # add_request_decorator Gws::LoginController, decorator
        add_request_decorator Fs::FilesController, decorator
      end

      it do
        # check that the logo is appeared on login form
        visit gws_login_path(site: site)
        within ".ss-logo-wrap" do
          expect(page).to have_css("img[alt='#{logo_application_name}']")

          info = image_element_info(first("img[alt='#{logo_application_name}']"))
          expect(info[:naturalWidth]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_WIDTH
          expect(info[:naturalHeight]).to be <= SS::Model::LogoSetting::LOGO_APPLICATION_IMAGE_HEIGHT
        end
      end
    end

    context "attach user file to image" do
      let!(:file) do
        tmp_ss_file(
          SS::UserFile, model: SS::UserFile::FILE_MODEL, user: gws_user, basename: "keyvisual-#{unique_id}.jpg",
          contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        )
      end

      before { login_gws_user }

      it do
        visit gws_site_path(site: site)
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          # open addon
          ensure_addon_opened("#addon-gws-agents-addons-system-logo_setting")

          # fill form
          within "#addon-gws-agents-addons-system-logo_setting" do
            fill_in "item[logo_application_name]", with: logo_application_name
            wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
          end
        end
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within ".cms-tabs" do
              click_on I18n.t("ss.buttons.select_from_list")
            end
          end
        end
        within_dialog do
          wait_for_event_fired "turbo:frame-load" do
            within "form.search" do
              check I18n.t("sns.user_file")
            end
          end
        end
        within_dialog do
          expect(page).to have_css('.file-view', text: file.name)
          wait_for_cbox_closed { click_on file.name }
        end
        within "form#item-form" do
          within "#addon-gws-agents-addons-system-logo_setting" do
            expect(page).to have_css('.humanized-name', text: file.humanized_name)
          end
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        site.reload
        expect(site.logo_application_name).to eq logo_application_name
        expect(site.logo_application_image).to be_present
        site.logo_application_image.tap do |image_file|
          # basic
          expect(image_file.id).not_to eq file.id # 複製が添付されるはずなので ID は不一致
          expect(image_file.model).to eq "ss/logo_file"
          expect(image_file.site_id).to be_blank
          expect(image_file.name).to eq file.name
          expect(image_file.filename).to eq file.filename
          expect(image_file.size).to be > 0
          expect(image_file.content_type).to eq file.content_type
          # owner item
          expect(image_file.owner_item_id).to eq site.id
          expect(image_file.owner_item_type).to eq site.class.name
          # other
          expect(image_file.user_id).to eq gws_user.id
        end

        SS::UserFile.find(file.id).tap do |after_file|
          expect(after_file.model).to eq "ss/user_file"
          expect(after_file.owner_item_id).to be_blank
          expect(after_file.owner_item_type).to be_blank
        end

        # check that logs is appeared on portal
        visit gws_portal_path(site: site)
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
    before { login_gws_user }

    it do
      visit gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      # open addon
      ensure_addon_opened("#addon-gws-agents-addons-system-logo_setting")

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
