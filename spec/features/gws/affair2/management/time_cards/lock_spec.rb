require 'spec_helper'

describe "gws_affair2_management_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:affair2) { gws_affair2 }

  let!(:attendance_date) { site.affair2_attendance_date }
  let!(:year_month) { attendance_date.strftime('%Y%m') }

  context "allowed with no attendance setting" do
    before { login_gws_user }

    it "#index" do
      visit gws_affair2_management_main_path(site)
      expect(page).to have_no_text(I18n.t("gws/affair2.notice.no_attendance_setting", user: user.long_name))
    end
  end

  context "basic" do
    context "manager user" do
      let(:user1) { affair2.users.u2 }
      let(:user2) { affair2.users.u12 }
      let(:user3) { affair2.users.u3 }

      it "#index" do
        # create timecards
        login_user(user1)
        visit gws_affair2_attendance_main_path(site)
        expect(page).to have_css(".attendance-box.today")

        login_user(user2)
        visit gws_affair2_attendance_main_path(site)
        expect(page).to have_css(".attendance-box.today")

        login_user(user3)
        visit gws_affair2_attendance_main_path(site)
        expect(page).to have_css(".attendance-box.today")

        expect(Gws::Affair2::Attendance::TimeCard.site(site).count).to eq 3
        item1 = Gws::Affair2::Attendance::TimeCard.site(site).user(user1).first
        item2 = Gws::Affair2::Attendance::TimeCard.site(site).user(user2).first
        item3 = Gws::Affair2::Attendance::TimeCard.site(site).user(user3).first
        expect(item1.unlocked?).to be_truthy
        expect(item2.unlocked?).to be_truthy
        expect(item3.unlocked?).to be_truthy

        # lock timecards
        login_user(user2)
        visit gws_affair2_management_main_path(site)
        expect(current_path).to eq gws_affair2_management_time_cards_path(site, affair2.groups.g1_1, year_month)
        wait_for_js_ready

        within "table.index tbody" do
          expect(page).to have_selector("tr", count: 2)
          expect(page).to have_text user1.long_name
          expect(page).to have_text user2.long_name
          expect(page).to have_no_text user3.long_name
        end

        within "#menu" do
          click_on I18n.t('gws/attendance.links.lock')
        end
        within "#addon-basic" do
          expect(page).to have_text(user1.long_name)
          expect(page).to have_text(user2.long_name)
          expect(page).to have_no_text user3.long_name
        end
        within "footer.send" do
          click_on I18n.t('gws/attendance.links.lock')
        end

        wait_for_notice I18n.t("gws/affair2.notice.started_lock")
        expect(enqueued_jobs.length).to eq 1

        item1.reload
        item2.reload
        item3.reload
        expect(item1.processing?).to be_truthy
        expect(item2.processing?).to be_truthy
        expect(item3.unlocked?).to be_truthy

        perform_enqueued_jobs
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        item1.reload
        item2.reload
        item3.reload
        expect(item1.locked?).to be_truthy
        expect(item2.locked?).to be_truthy
        expect(item3.unlocked?).to be_truthy

        # unlock timecards
        visit gws_affair2_management_main_path(site)
        expect(current_path).to eq gws_affair2_management_time_cards_path(site, affair2.groups.g1_1, year_month)
        wait_for_js_ready

        within "table.index tbody" do
          expect(page).to have_selector("tr", count: 2)
          expect(page).to have_text user1.long_name
          expect(page).to have_text user2.long_name
          expect(page).to have_no_text user3.long_name
        end

        within "#menu" do
          click_on I18n.t('gws/attendance.links.unlock')
        end
        within "#addon-basic" do
          expect(page).to have_text(user1.long_name)
          expect(page).to have_text(user2.long_name)
          expect(page).to have_no_text user3.long_name
        end
        within "footer.send" do
          click_on I18n.t('gws/attendance.links.unlock')
        end

        wait_for_notice I18n.t("gws/affair2.notice.started_unlock")
        expect(enqueued_jobs.length).to eq 1

        item1.reload
        item2.reload
        item3.reload
        expect(item1.processing?).to be_truthy
        expect(item2.processing?).to be_truthy
        expect(item3.unlocked?).to be_truthy

        perform_enqueued_jobs
        expect(Job::Log.count).to eq 2
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        item1.reload
        item2.reload
        item3.reload
        expect(item1.unlocked?).to be_truthy
        expect(item2.unlocked?).to be_truthy
        expect(item3.unlocked?).to be_truthy
      end
    end
  end
end
