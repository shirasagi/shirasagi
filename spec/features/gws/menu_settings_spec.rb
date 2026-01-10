require 'spec_helper'

describe "gws_menu_settings", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_portal_path site }

  context "with auth" do
    before do
      @save_file_upload_dialog = SS.file_upload_dialog
      SS.file_upload_dialog = :v2
    end

    after do
      SS.file_upload_dialog = @save_file_upload_dialog
    end

    before { login_gws_user }

    context "basic" do
      it do
        visit index_path
        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end

        #
        # メニュー設定の詳細画面の初期状態を確認
        #
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        within "#addon-gws-agents-addons-system-menu_setting" do
          expect(page).to have_css("span.ss-icon.ss-icon-portal")
          expect(page).to have_css("span.ss-icon.ss-icon-notice")
          expect(page).to have_css("span.ss-icon.ss-icon-schedule")
          expect(page).to have_css("span.ss-icon.ss-icon-todo")
          expect(page).to have_css("span.ss-icon.ss-icon-reminder")
          expect(page).to have_css("span.ss-icon.ss-icon-presence")
          expect(page).to have_css("span.ss-icon.ss-icon-attendance")
          expect(page).to have_css("span.ss-icon.ss-icon-affair")
          expect(page).to have_css("span.ss-icon.ss-icon-daily-report")
          expect(page).to have_css("span.ss-icon.ss-icon-bookmark")
          expect(page).to have_css("span.ss-icon.ss-icon-memo")
          expect(page).to have_css("span.ss-icon.ss-icon-workload")
          expect(page).to have_css("span.ss-icon.ss-icon-report")
          expect(page).to have_css("span.ss-icon.ss-icon-workflow")
          expect(page).to have_css("span.ss-icon.ss-icon-workflow2")
          expect(page).to have_css("span.ss-icon.ss-icon-circular")
          expect(page).to have_css("span.ss-icon.ss-icon-monitor")
          expect(page).to have_css("span.ss-icon.ss-icon-survey")
          expect(page).to have_css("span.ss-icon.ss-icon-board")
          expect(page).to have_css("span.ss-icon.ss-icon-faq")
          expect(page).to have_css("span.ss-icon.ss-icon-qna")
          expect(page).to have_css("span.ss-icon.ss-icon-discussion")
          expect(page).to have_css("span.ss-icon.ss-icon-share")
          expect(page).to have_css("span.ss-icon.ss-icon-shared-address")
          expect(page).to have_css("span.ss-icon.ss-icon-personal-address")
          expect(page).to have_css("span.ss-icon.ss-icon-tabular")
          expect(page).to have_css("span.ss-icon.ss-icon-elasticsearch")
          expect(page).to have_css("span.ss-icon.ss-icon-conf")
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          #
          # ポータルのアイコンを変更
          #
          ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
          within "#addon-gws-agents-addons-system-menu_setting" do
            upload_to_ss_file_field "item[menu_portal_icon_image_id]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        within "#addon-gws-agents-addons-system-menu_setting" do
          expect(page).to have_css(".addon-gws-system-menu-setting img.icon-portal[src*='logo.png']")
        end

        #
        # 変更後のアイコンの状態を確認
        #
        visit index_path
        within ".main-navi" do
          expect(page).to have_css(".icon-portal.has-custom-icon")
          expect(page).to have_css("img.nav-icon-img[src*='logo.png']")
          expect(page).to have_no_css("span.ss-icon.ss-icon-portal")

          image_element_info(first("img.nav-icon-img[src*='logo.png']")).tap do |image_info|
            expect(image_info[:currentSrc]).to be_present
            expect(image_info[:width]).to be > 10
            expect(image_info[:height]).to be > 10
          end
        end
      end
    end

    context "multiple menu icons" do
      # ポータルとスケジュールのアイコンを変更
      let(:menu_types) { %i[portal schedule] }

      it "changes multiple menu icons" do
        visit index_path
        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end
        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
          within "#addon-gws-agents-addons-system-menu_setting" do
            menu_types.each do |menu_type|
              upload_to_ss_file_field "item[menu_#{menu_type}_icon_image_id]", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # 複数のアイコンが変更されていることを確認
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        within "#addon-gws-agents-addons-system-menu_setting" do
          menu_types.each do |menu_type|
            within ".menu-setting-#{menu_type}" do
              expect(page).to have_css("img.icon-#{menu_type}[src*='logo.png']")
            end
          end
        end

        visit index_path
        within ".main-navi" do
          within ".icon-portal" do
            expect(page).to have_css("img.nav-icon-img[src*='logo.png']")
            expect(page).to have_no_css("icon-portal.has-font-icon")

            image_element_info(first("img.nav-icon-img[src*='logo.png']")).tap do |image_info|
              expect(image_info[:currentSrc]).to be_present
              expect(image_info[:width]).to be > 10
              expect(image_info[:height]).to be > 10
            end
          end
          within ".icon-schedule" do
            expect(page).to have_css("img.nav-icon-img[src*='logo.png']")
            expect(page).to have_no_css("icon-schedule.has-font-icon")

            image_element_info(first("img.nav-icon-img[src*='logo.png']")).tap do |image_info|
              expect(image_info[:currentSrc]).to be_present
              expect(image_info[:width]).to be > 10
              expect(image_info[:height]).to be > 10
            end
          end
        end
      end
    end

    context "icon removal" do
      it "removes uploaded icon and restores default" do
        visit index_path
        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end
        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          # アイコンをアップロード
          ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
          within "#addon-gws-agents-addons-system-menu_setting" do
            upload_to_ss_file_field "item[menu_portal_icon_image_id]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # アイコンがアップロードされていることを確認
        within ".menu-setting-portal" do
          expect(page).to have_css("img.icon-portal[src*='logo.png']")
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          # アイコンを削除
          ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
          within "#addon-gws-agents-addons-system-menu_setting" do
            within ".menu-setting-portal" do
              click_on I18n.t("ss.buttons.delete")
            end
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # デフォルトアイコンに戻っていることを確認
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        within "#addon-gws-agents-addons-system-menu_setting" do
          within ".menu-setting-portal" do
            expect(page).to have_css("span.ss-icon.ss-icon-portal")
            expect(page).to have_no_css("img.icon-portal[src*='logo.png']")
          end
        end

        visit index_path
        within ".main-navi" do
          expect(page).to have_css(".icon-portal.has-font-icon")
          expect(page).to have_no_css(".icon-portal.has-custom-icon")
          expect(page).to have_no_css("img.nav-icon-img[src*='logo.png']")
        end
      end
    end

    context "svg file upload and different user sees uploaded icon" do
      let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
      let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }

      it "user1 uploads icon and user2 sees it" do
        # user1でログインしてアイコンをアップロード
        login_user user1, to: index_path
        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          # SVGファイルをアップロード
          ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
          within "#addon-gws-agents-addons-system-menu_setting" do
            upload_to_ss_file_field "item[menu_portal_icon_image_id]", "#{Rails.root}/spec/fixtures/ss/test_icon.svg"
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # SVGアイコンが表示されていることを確認
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        within "#addon-gws-agents-addons-system-menu_setting" do
          within ".menu-setting-portal" do
            expect(page).to have_css("img.icon-portal[src*='test_icon.svg']")
          end
        end

        # ポータルページでSVGアイコンが表示されていることを確認
        visit index_path
        within ".main-navi" do
          expect(page).to have_css(".icon-portal.has-custom-icon")
          expect(page).to have_css("img.nav-icon-img[src*='test_icon.svg']")
          expect(page).to have_no_css("span.ss-icon.ss-icon-portal")

          image_element_info(first("img.nav-icon-img[src*='test_icon.svg']")).tap do |image_info|
            expect(image_info[:currentSrc]).to be_present
            expect(image_info[:width]).to be > 10
            expect(image_info[:height]).to be > 10
          end
        end

        # user2でログインし、アイコンの閲覧に支障がないことを確認
        login_user user2, to: index_path

        # user2でもアップロードされたアイコンが表示されることを確認
        within ".main-navi" do
          expect(page).to have_css(".icon-portal.has-custom-icon")
          expect(page).to have_css("img.nav-icon-img[src*='test_icon.svg']")
          expect(page).to have_no_css("span.ss-icon.ss-icon-portal")

          image_element_info(first("img.nav-icon-img[src*='test_icon.svg']")).tap do |image_info|
            expect(image_info[:currentSrc]).to be_present
            expect(image_info[:width]).to be > 10
            expect(image_info[:height]).to be > 10
          end
        end
      end
    end
  end
end
