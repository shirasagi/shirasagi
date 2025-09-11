require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let(:index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }

  let(:name) { unique_id }
  let(:today) { Time.zone.today }
  let(:start_on) { today.beginning_of_month }
  let(:end_on) { today.end_of_month }
  let(:color) { "#481357" }
  let(:close_date) { today - 1.day }

  before { login_gws_user }

  context "with readable post" do
    it do
      visit index_path
      wait_for_all_turbo_frames

      within "#menu" do
        click_on I18n.t("ss.links.new")
      end
      within 'form#item-form' do
        fill_in "item[name]", with: name
        fill_in_date "item[start_on]", with: start_on
        fill_in_date "item[end_on]", with: start_on
        fill_in_color "item[color]", with: color
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-gws-agents-addons-notice-calendar" do
        click_on "calendar_month"
      end
      # wait for ajax completion
      wait_for_all_turbo_frames
      within "#content-navi-core .gws-notice-folder" do
        expect(page).to have_link(folder.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: name)
      end
    end
  end

  context "with back number post" do
    context "with use_gws_notice_back_number" do
      it do
        visit index_path
        wait_for_all_turbo_frames

        within "#menu" do
          click_on I18n.t("ss.links.new")
        end
        within 'form#item-form' do
          fill_in "item[name]", with: name
          fill_in_date "item[start_on]", with: start_on
          fill_in_date "item[end_on]", with: start_on
          fill_in_color "item[color]", with: color

          ensure_addon_opened "#addon-ss-agents-addons-release"
          within "#addon-ss-agents-addons-release" do
            fill_in_datetime "item[close_date]", with: close_date
          end

          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within "#addon-gws-agents-addons-notice-calendar" do
          click_on "calendar_month"
        end
        # wait for ajax completion
        wait_for_all_turbo_frames
        within "#content-navi-core .gws-notice-folder" do
          expect(page).to have_link(folder.name)
        end
        within ".gws-schedule-box" do
          expect(page).to have_css(".fc-event-name", text: name)
        end
      end
    end

    context "without use_gws_notice_back_number" do
      before do
        gws_user.gws_roles.to_a.each do |gws_role|
          gws_role.permissions = gws_role.permissions - %w(use_gws_notice_back_number)
          gws_role.save!
        end
      end

      it do
        visit index_path

        within "#menu" do
          click_on I18n.t("ss.links.new")
        end
        within 'form#item-form' do
          fill_in "item[name]", with: name
          fill_in_date "item[start_on]", with: start_on
          fill_in_date "item[end_on]", with: start_on
          fill_in_color "item[color]", with: color

          ensure_addon_opened "#addon-ss-agents-addons-release"
          within "#addon-ss-agents-addons-release" do
            fill_in_datetime "item[close_date]", with: close_date
          end

          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within "#addon-gws-agents-addons-notice-calendar" do
          # バックナンバーを利用する権限がない場合、カレンダーへのリンクは生成しない
          expect(page).to have_no_css(".index-calendar-link")
        end
      end
    end
  end

  context "with non-published post" do
    it do
      visit index_path

      within "#menu" do
        click_on I18n.t("ss.links.new")
      end
      within 'form#item-form' do
        fill_in "item[name]", with: name
        fill_in_date "item[start_on]", with: start_on
        fill_in_date "item[end_on]", with: start_on
        fill_in_color "item[color]", with: color

        ensure_addon_opened "#addon-ss-agents-addons-release"
        within "#addon-ss-agents-addons-release" do
          select I18n.t("ss.state.closed"), from: "item[state]"
        end

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-gws-agents-addons-notice-calendar" do
        expect(page).to have_no_css(".index-calendar-link")
      end
    end
  end
end
