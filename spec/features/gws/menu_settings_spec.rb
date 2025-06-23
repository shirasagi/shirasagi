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
        expect(page).to have_css("svg.icon-portal")
        expect(page).to have_css("svg.icon-notice")
        expect(page).to have_css("svg.icon-schedule")
        expect(page).to have_css("svg.icon-todo")
        expect(page).to have_css("svg.icon-reminder")
        expect(page).to have_css("svg.icon-presence")
        expect(page).to have_css("svg.icon-attendance")
        expect(page).to have_css("svg.icon-affair")
        expect(page).to have_css("svg.icon-affair2")
        expect(page).to have_css("svg.icon-daily_report")
        expect(page).to have_css("svg.icon-bookmark")
        expect(page).to have_css("svg.icon-memo")
        expect(page).to have_css("svg.icon-workload")
        expect(page).to have_css("svg.icon-report")
        expect(page).to have_css("svg.icon-workflow")
        expect(page).to have_css("svg.icon-workflow2")
        expect(page).to have_css("svg.icon-circular")
        expect(page).to have_css("svg.icon-monitor")
        expect(page).to have_css("svg.icon-survey")
        expect(page).to have_css("svg.icon-board")
        expect(page).to have_css("svg.icon-faq")
        expect(page).to have_css("svg.icon-qna")
        expect(page).to have_css("svg.icon-discussion")
        expect(page).to have_css("svg.icon-share")
        expect(page).to have_css("svg.icon-shared_address")
        expect(page).to have_css("svg.icon-personal_address")
        expect(page).to have_css("svg.icon-elasticsearch")
        expect(page).to have_css("svg.icon-conf")

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
          expect(page).to have_no_css("svg.icon-portal")
          expect(page).to have_css(".icon-portal.has-custom-icon")
          expect(page).to have_css("img.nav-icon-img[src*='logo.png']")
        end
      end
    end
  end
end
