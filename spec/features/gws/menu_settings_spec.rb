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
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        #
        # メニュー設定の詳細画面の初期状態を確認
        #
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

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        #
        # ポータルのアイコンを変更
        #

        within all(".addon-gws-system-menu-setting").first do
          within find("dt", text: I18n.t("gws.buttons.change_menu_icon")).find(:xpath, "following-sibling::dd") do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
          end
          wait_for_cbox_closed do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within all(".addon-gws-system-menu-setting").first do
          within find("dt", text: I18n.t("gws.buttons.change_menu_icon")).find(:xpath, "following-sibling::dd") do
            expect(page).to have_css(".file-view", text: /logo/)
          end
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        wait_for_ajax
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        within all(".addon-gws-system-menu-setting").first do
          expect(page).to have_css("img.icon-portal[src*='logo.png']")
        end

        #
        # 変更後のアイコンの状態を確認
        #
        visit index_path
        wait_for_js_ready
        within ".main-navi" do
          expect(page).to have_no_css("span.ss-icon.ss-icon-portal")
          expect(page).to have_css(".icon-portal.has-custom-icon")
          expect(page).to have_css("img.nav-icon-img[src*='logo.png']")
        end
      end
    end

    context "multiple menu icons" do
      it "changes multiple menu icons" do
        visit index_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        # ポータルとスケジュールのアイコンを変更
        menu_types = [:portal, :schedule]
        menu_types.each do |menu_type|
          within(all(".addon-gws-system-menu-setting").find { |el| el.has_css?("span.ss-icon.ss-icon-#{menu_type}") }) do
            within find("dt", text: I18n.t("gws.buttons.change_menu_icon")).find(:xpath, "following-sibling::dd") do
              wait_for_cbox_opened do
                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
            wait_for_cbox_closed do
              within "form" do
                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # 複数のアイコンが変更されていることを確認
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        menu_types.each do |menu_type|
          within(all(".addon-gws-system-menu-setting").find { |el| el.has_css?("img.icon-#{menu_type}") }) do
            expect(page).to have_css("img.icon-#{menu_type}[src*='logo.png']")
          end
        end
        visit index_path
        wait_for_js_ready
        within ".main-navi" do
          within ".icon-portal" do
            expect(page).to have_no_css("icon-portal.has-font-icon")
            expect(page).to have_css("img.nav-icon-img[src*='logo.png']")
          end
          within ".icon-schedule" do
            expect(page).to have_no_css("icon-schedule.has-font-icon")
            expect(page).to have_css("img.nav-icon-img[src*='logo.png']")
          end
        end
      end
    end

    context "icon removal" do
      it "removes uploaded icon and restores default" do
        visit index_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        # アイコンをアップロード
        within all(".addon-gws-system-menu-setting").first do
          within find("dt", text: I18n.t("gws.buttons.change_menu_icon")).find(:xpath, "following-sibling::dd") do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
          end
          wait_for_cbox_closed do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        # アイコンがアップロードされていることを確認
        within all(".addon-gws-system-menu-setting").first do
          expect(page).to have_css("img.icon-portal[src*='logo.png']")
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        # アイコンを削除
        within all(".addon-gws-system-menu-setting").first do
          within find("dt", text: I18n.t("gws.buttons.change_menu_icon")).find(:xpath, "following-sibling::dd") do
            click_on I18n.t("ss.buttons.delete")
          end
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
        # デフォルトアイコンに戻っていることを確認
        within all(".addon-gws-system-menu-setting").first do
          expect(page).to have_css("span.ss-icon.ss-icon-portal")
          expect(page).to have_no_css("img.icon-portal[src*='logo.png']")
        end

        visit index_path
        wait_for_js_ready
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
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".main-navi" do
          click_on I18n.t("gws.site_config")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        # SVGファイルをアップロード
        within all(".addon-gws-system-menu-setting").first do
          within find("dt", text: I18n.t("gws.buttons.change_menu_icon")).find(:xpath, "following-sibling::dd") do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/test_icon.svg"
          end
          wait_for_cbox_closed do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end

        # SVGファイルが正常にアップロードされていることを確認
        within all(".addon-gws-system-menu-setting").first do
          within find("dt", text: I18n.t("gws.buttons.change_menu_icon")).find(:xpath, "following-sibling::dd") do
            expect(page).to have_css(".file-view", text: /test_icon/)
          end
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        wait_for_ajax
        wait_for_js_ready
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")

        # SVGアイコンが表示されていることを確認
        within all(".addon-gws-system-menu-setting").first do
          expect(page).to have_css("img.icon-portal[src*='test_icon.svg']")
        end

        # ポータルページでSVGアイコンが表示されていることを確認
        visit index_path
        wait_for_js_ready
        within ".main-navi" do
          expect(page).to have_no_css("span.ss-icon.ss-icon-portal")
          expect(page).to have_css(".icon-portal.has-custom-icon")
          expect(page).to have_css("img.nav-icon-img[src*='test_icon.svg']")
        end

        # user1をログアウトしてuser2でログイン
        within ".user-navigation" do
          wait_for_event_fired("turbo:frame-load") { click_on user1.name }
          click_on I18n.t("ss.logout")
        end
        login_user user2, to: index_path
        wait_for_js_ready

        # user2でもアップロードされたアイコンが表示されることを確認
        within ".main-navi" do
          expect(page).to have_no_css("span.ss-icon.ss-icon-portal")
          expect(page).to have_css(".icon-portal.has-custom-icon")
          expect(page).to have_css("img.nav-icon-img[src*='test_icon.svg']")
        end
      end
    end
  end
end
