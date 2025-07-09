require 'spec_helper'

describe "gws_workload_works", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:show_path) { gws_workload_work_path site, item }

  context "with auth" do
    before { login_gws_user }

    context "comment at current date 1" do
      let(:today) { Time.zone.parse("2022/6/1").to_date }
      let(:year) { 2022 }
      let(:due_date) { today + 7 }
      let(:due_start_on) { today - 7 }
      let(:due_end_on) { today }
      let(:item) { create :gws_workload_work, year: year, due_date: due_date, due_start_on: due_start_on, due_end_on: nil }

      it "#show" do
        Timecop.travel(today) do
          item
          visit show_path

          # comment 30% 2:00
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "30"
              select "2", from: "item[in_worktime_hours]"
              select "0", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "30%")
              expect(page).to have_css(".worktime-minutes", text: "2:00")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          # comment 100% 1:15
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "100"
              select "1", from: "item[in_worktime_hours]"
              select "15", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "100%")
              expect(page).to have_css(".worktime-minutes", text: "3:15")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end

      it "#show" do
        Timecop.travel(today) do
          visit show_path
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          within ".nav-menu" do
            expect(page).to have_no_link I18n.t("gws/schedule/todo.links.revert")
            expect(page).to have_link I18n.t("gws/schedule/todo.links.finish")

            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          within "form#item-form" do
            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          wait_for_notice I18n.t('ss.notice.saved')
          item.reload

          within ".gws-comment-post" do
            within "#comment-#{item.last_comment.id}" do
              expect(page).to have_css(".achievement-rate", text: "100%")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end
    end

    context "comment at current date 2" do
      let(:today) { Time.zone.parse("2022/4/1").to_date }
      let(:year) { 2021 }
      let(:due_date) { today }
      let(:due_start_on) { today - 1 }
      let(:due_end_on) { today }
      let(:item) { create :gws_workload_work, year: year, due_date: due_date, due_start_on: due_start_on, due_end_on: nil }

      it "#show" do
        Timecop.travel(today) do
          item
          visit show_path

          # comment 30% 2:00
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "30"
              select "2", from: "item[in_worktime_hours]"
              select "0", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "30%")
              expect(page).to have_css(".worktime-minutes", text: "2:00")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          # comment 100% 1:15
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "100"
              select "1", from: "item[in_worktime_hours]"
              select "15", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "100%")
              expect(page).to have_css(".worktime-minutes", text: "3:15")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end

      it "#show" do
        Timecop.travel(today) do
          visit show_path
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          within ".nav-menu" do
            expect(page).to have_no_link I18n.t("gws/schedule/todo.links.revert")
            expect(page).to have_link I18n.t("gws/schedule/todo.links.finish")

            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          within "form#item-form" do
            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          wait_for_notice I18n.t('ss.notice.saved')
          item.reload

          within ".gws-comment-post" do
            within "#comment-#{item.last_comment.id}" do
              expect(page).to have_css(".achievement-rate", text: "100%")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end
    end

    context "comment at before date" do
      let(:today) { Time.zone.parse("2022/6/1").to_date }
      let(:year) { 2022 }
      let(:due_date) { today - 14 }
      let(:due_start_on) { today - 21 }
      let(:due_end_on) { due_date }
      let(:item) { create :gws_workload_work, year: year, due_date: due_date, due_start_on: due_start_on, due_end_on: nil }

      it "#show" do
        Timecop.travel(today) do
          item
          visit show_path

          # comment 30% 2:00
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "30"
              select "2", from: "item[in_worktime_hours]"
              select "0", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "30%")
              expect(page).to have_css(".worktime-minutes", text: "2:00")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          # comment 100% 1:15
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "100"
              select "1", from: "item[in_worktime_hours]"
              select "15", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "100%")
              expect(page).to have_css(".worktime-minutes", text: "3:15")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end

      it "#show" do
        Timecop.travel(today) do
          visit show_path
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          within ".nav-menu" do
            expect(page).to have_no_link I18n.t("gws/schedule/todo.links.revert")
            expect(page).to have_link I18n.t("gws/schedule/todo.links.finish")

            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          within "form#item-form" do
            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          wait_for_notice I18n.t('ss.notice.saved')
          item.reload

          within ".gws-comment-post" do
            within "#comment-#{item.last_comment.id}" do
              expect(page).to have_css(".achievement-rate", text: "100%")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end
    end

    context "comment at after date" do
      let(:today) { Time.zone.parse("2022/6/1").to_date }
      let(:year) { 2022 }
      let(:due_date) { today + 21 }
      let(:due_start_on) { today + 14 }
      let(:due_end_on) { due_start_on }
      let(:item) { create :gws_workload_work, year: year, due_date: due_date, due_start_on: due_start_on, due_end_on: nil }

      it "#show" do
        Timecop.travel(today) do
          item
          visit show_path

          # comment 30% 2:00
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "30"
              select "2", from: "item[in_worktime_hours]"
              select "0", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "30%")
              expect(page).to have_css(".worktime-minutes", text: "2:00")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          # comment 100% 1:15
          within "#addon-gws-agents-addons-workload-comment_post" do
            within "#comment-form" do
              fill_in "item[achievement_rate]", with: "100"
              select "1", from: "item[in_worktime_hours]"
              select "15", from: "item[in_worktime_minutes]"
              fill_in "item[text]", with: unique_id
              click_on I18n.t('gws/workload.buttons.comment')
            end
          end
          wait_for_notice I18n.t('ss.notice.saved')

          within "#addon-gws-agents-addons-workload-comment_post" do
            within ".comment.total" do
              expect(page).to have_css(".achievement-rate", text: "100%")
              expect(page).to have_css(".worktime-minutes", text: "3:15")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end

      it "#show" do
        Timecop.travel(today) do
          visit show_path
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_no_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end

          within ".nav-menu" do
            expect(page).to have_no_link I18n.t("gws/schedule/todo.links.revert")
            expect(page).to have_link I18n.t("gws/schedule/todo.links.finish")

            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          within "form#item-form" do
            click_on I18n.t("gws/schedule/todo.links.finish")
          end
          wait_for_notice I18n.t('ss.notice.saved')
          item.reload

          within ".gws-comment-post" do
            within "#comment-#{item.last_comment.id}" do
              expect(page).to have_css(".achievement-rate", text: "100%")
            end
          end
          within "#addon-basic" do
            expect(page).to have_css(".due-date", text: due_date.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-start-on", text: due_start_on.strftime('%Y/%m/%d'))
            expect(page).to have_css(".due-end-on", text: due_end_on.strftime('%Y/%m/%d'))
          end
        end
      end
    end

    context "work registration and schedule reflection" do

      let(:today) { Time.zone.parse("2025/7/9").to_date }
      let(:year) { 2025 }
      let(:due_date) { today }
      let(:due_start_on) { today }
      let(:item_name) { "E2Eテスト業務予定" }
      let(:item) do
        create :gws_workload_work, name: item_name, year: year, due_date: due_date, due_start_on: due_start_on, due_end_on: nil
      end
      let(:schedule_plans_path) { gws_schedule_plans_path(site) }

      it "Newly registered workload is reflected as an all-day event in the schedule calendar and list" do
        Timecop.travel(today) do
          item
          visit schedule_plans_path

          # カレンダー画面で該当予定が表示されているか確認
          expect(page).to have_content(item_name)

          # 「リスト」ボタンをクリックしてリスト画面に遷移
          click_on I18n.t("gws/schedule.calendar.buttonText.listMonth")
          # リスト画面で該当予定が表示されているか確認
          expect(page).to have_content(item_name)
          # 日本語形式または英語形式の日付と終日ラベルを確認
          japanese_format = "#{due_date.strftime('%Y年 %-m月%-d日')} (#{I18n.t('date.abbr_day_names')[due_date.wday]}) #{I18n.t('gws/schedule.options.allday.allday')}"
          english_format = "#{due_date.strftime('%a, %m/%d/%Y')} #{I18n.t('gws/schedule.options.allday.allday')}"

          expect(page).to have_css(".td.startAt", text: japanese_format).or have_css(".td.startAt", text: english_format)
          expect(page).to have_css(".td.endAt", text: japanese_format).or have_css(".td.endAt", text: english_format)
        end
      end
    end
  end
end
