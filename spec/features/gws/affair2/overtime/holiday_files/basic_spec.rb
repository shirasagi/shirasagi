require 'spec_helper'

describe "gws_affair2_overtime_holiday_files", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  let(:month) do
    month = Time.zone.parse("2025/1/1")
    month = month.advance(minutes: site.affair2_time_changed_minute)
    month
  end
  let(:time_card_title) do
    month = Time.zone.parse("2025/1/1").to_date
    I18n.t('gws/attendance.formats.time_card_name', month: I18n.l(month, format: :attendance_year_month))
  end

  context "denied with no attendance setting" do
    let!(:user) { gws_user }

    it "#index" do
      Timecop.travel(month) do
        login_user(user)

        visit gws_affair2_overtime_holiday_files_path site
        expect(page).to have_text(I18n.t("gws/affair2.notice.no_attendance_setting", user: user.long_name))
      end
    end
  end

  context "basic" do
    def create_time_card
      visit gws_affair2_attendance_main_path(site)

      within ".attendance-box.monthly" do
        expect(page).to have_css(".attendance-box-title", text: time_card_title)
        expect(page).to have_css(".day-1.current")
      end
    end

    def create_overtime_file
      visit new_gws_affair2_overtime_holiday_file_path(site)

      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in_datetime "item[in_date]", with: "2025/1/11"
        select "17", from: "item_in_start_hour"
        select "15", from: "item_in_start_minute"
        select "18", from: "item_in_close_hour"
        select "15", from: "item_in_close_minute"
        choose "item_expense_settle"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      Gws::Affair2::Overtime::HolidayFile.first
    end

    context "regular user" do
      let!(:user) { affair2.users.u3 }
      let!(:group) { affair2.groups.g1_1_1 }
      #let(:item) do
      #  create(:gws_affair2_overtime_holiday_file,
      #    cur_user: user,
      #    in_date: "2025/1/11",
      #    in_start_hour: 17,
      #    in_start_minute: 15,
      #    in_close_hour: 18,
      #    in_close_minute: 15,
      #    expense: "settle",
      #    group_ids: [group.id])
      #end

      it "#index" do
        Timecop.travel(month) do
          login_user(user)

          create_time_card

          item = create_overtime_file
          visit gws_affair2_overtime_holiday_files_path(site)

          within ".list-items" do
            expect(page).to have_link item.long_name
          end
        end
      end

      it "#show" do
        Timecop.travel(month) do
          login_user(user)

          create_time_card

          item = create_overtime_file
          visit gws_affair2_overtime_holiday_file_path(site, item)

          expect(page).to have_css("#addon-basic", text: item.name)
        end
      end

      it "#new" do
        Timecop.travel(month) do
          login_user(user)

          create_time_card

          create_overtime_file
        end
      end

      it "#edit" do
        Timecop.travel(month) do
          login_user(user)

          create_time_card

          item = create_overtime_file
          visit edit_gws_affair2_overtime_holiday_file_path(site, item)

          within "form#item-form" do
            click_button I18n.t('ss.buttons.save')
          end
          wait_for_notice I18n.t("ss.notice.saved")
        end
      end

      it "#delete" do
        Timecop.travel(month) do
          login_user(user)

          create_time_card

          item = create_overtime_file
          visit delete_gws_affair2_overtime_holiday_file_path(site, item)

          within "form#item-form" do
            click_button I18n.t('ss.buttons.delete')
          end
          wait_for_notice I18n.t("ss.notice.deleted")
          within ".list-items" do
            expect(page).to have_no_css(".list-item")
          end
        end
      end
    end
  end
end
