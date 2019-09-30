require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.change(hour: rand(8..12), min: rand(0..59)) }
  let(:edit_at) { Time.zone.now.change(hour: rand(15..20), min: rand(0..59)) }
  let(:other_day) { now.day <= 15 ? 26 : 5 }

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  context 'without login' do
    xit do
      visit gws_attendance_main_path(site)
      expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
    end
  end

  context 'without permissions' do
    let!(:user) { create(:gws_user, group_ids: [ site.id ]) }

    before do
      login_user user
    end

    xit do
      visit gws_attendance_main_path(site)
      within ".main-navi" do
        expect(page).to have_no_css("a", text: I18n.t('modules.gws/attendance'))
      end
    end
  end

  context "when user has only 'use_gws_attendance_time_cards' permission" do
    let!(:role) { create(:gws_role_attendance_user) }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: [ role.id ]) }

    around do |example|
      travel_to(now) { example.run }
    end

    before do
      login_user user
    end

    shared_examples "time cell is only punchable" do
      context "cell in today row" do
        xit do
          visit gws_attendance_main_path(site)
          expect(page).to have_css(".today .info .#{cell_type}", text: '--:--')
          expect(page).to have_css("tr.current td.#{cell_type}", text: '--:--')

          # punch
          within ".today .action .#{cell_type}" do
            page.accept_confirm do
              click_on I18n.t('gws/attendance.buttons.punch')
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
          expect(page).to have_css(".today .info .#{cell_type}", text: format('%d:%02d', now.hour, now.min))
          expect(page).to have_css("tr.current td.#{cell_type}", text: format('%d:%02d', now.hour, now.min))

          # edit is not shown
          within ".today .action .#{cell_type}" do
            expect(page).to have_no_css("button[name=edit]")
          end

          # popup is not shown on current row
          within "table.time-card" do
            within "tr.current" do
              first("td.#{cell_type}").click
              expect(page).to have_css("td.#{cell_type}.focus")
            end
          end
          expect(page).to have_no_css('.cell-toolbar', visible: true)

          # popup is also not shown on no-current row
          within "table.time-card" do
            within "tr.day-#{other_day}" do
              first("td.#{cell_type}").click
              expect(page).to have_css("td.#{cell_type}.focus")
            end
          end
          expect(page).to have_no_css('.cell-toolbar', visible: true)
        end
      end

      context "cell in monthly table" do
        xit do
          visit gws_attendance_main_path(site)
          expect(page).to have_css(".today .info .#{cell_type}", text: '--:--')
          expect(page).to have_css("tr.current td.#{cell_type}", text: '--:--')

          # punch
          within "table.time-card" do
            within "tr.current" do
              first("td.#{cell_type}").click
            end
          end
          within '.cell-toolbar' do
            page.accept_confirm do
              click_on I18n.t('gws/attendance.links.punch')
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
          expect(page).to have_css(".today .info .#{cell_type}", text: format('%d:%02d', now.hour, now.min))
          expect(page).to have_css("tr.current td.#{cell_type}", text: format('%d:%02d', now.hour, now.min))

          # edit is not shown
          within ".today .action .#{cell_type}" do
            expect(page).to have_no_css("button[name=edit]")
          end

          # popup is not shown on current row
          within "table.time-card" do
            within "tr.current" do
              first("td.#{cell_type}").click
              expect(page).to have_css("td.#{cell_type}.focus")
            end
          end
          expect(page).to have_no_css('.cell-toolbar', visible: true)

          # popup is also not shown on no-current row
          within "table.time-card" do
            within "tr.day-#{other_day}" do
              first("td.#{cell_type}").click
              expect(page).to have_css("td.#{cell_type}.focus")
            end
          end
          expect(page).to have_no_css('.cell-toolbar', visible: true)
        end
      end
    end

    context "with enter" do
      let(:cell_type) { "enter" }
      include_context "time cell is only punchable"
    end

    context "with leave" do
      let(:cell_type) { "leave" }
      include_context "time cell is only punchable"
    end

    context "with break_enter1" do
      let(:cell_type) { "break_enter1" }
      include_context "time cell is only punchable"
    end

    context 'with break_leave1' do
      let(:cell_type) { "break_leave1" }
      include_context "time cell is only punchable"
    end

    context 'with memo' do
      let(:memo) { unique_id }

      context "cell in today row" do
        xit do
          visit gws_attendance_main_path(site)
          expect(page).to have_css(".today .info .memo", text: '')
          expect(page).to have_css("tr.current td.memo", text: '')

          # create memo
          within ".today .action .memo" do
            click_on I18n.t('ss.buttons.edit')
          end
          wait_for_cbox do
            fill_in 'record[memo]', with: memo
            click_on I18n.t('ss.buttons.save')
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css('.today .info .memo', text: memo)
          expect(page).to have_css('tr.current td.memo', text: memo)

          # edit is shown
          within ".today .action .memo" do
            expect(page).to have_css("button[name=edit]")
          end

          # popup is shown on current row
          within "table.time-card" do
            within "tr.current" do
              first("td.memo").click
              expect(page).to have_css("td.memo.focus")
            end
          end
          expect(page).to have_css('.cell-toolbar', visible: true)
          expect(page).to have_link(I18n.t("ss.links.edit"), visible: true)

          # popup is not shown on no-current row
          within "table.time-card" do
            within "tr.day-#{other_day}" do
              first("td.memo").click
              expect(page).to have_css("td.memo.focus")
            end
          end
          expect(page).to have_no_css('.cell-toolbar', visible: true)
          expect(page).to have_no_link(I18n.t("ss.links.edit"), visible: true)
        end
      end

      context "cell in monthly table" do
        xit do
          visit gws_attendance_main_path(site)
          expect(page).to have_css(".today .info .memo", text: '')
          expect(page).to have_css("tr.current td.memo", text: '')

          # create new memo
          within "table.time-card" do
            within "tr.current" do
              first("td.memo").click
            end
          end
          within '.cell-toolbar' do
            click_on I18n.t('ss.links.edit')
          end
          wait_for_cbox do
            fill_in 'record[memo]', with: memo
            click_on I18n.t('ss.buttons.save')
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css('.today .info .memo', text: memo)
          expect(page).to have_css('tr.current td.memo', text: memo)

          # edit is shown
          within ".today .action .memo" do
            expect(page).to have_css("button[name=edit]")
          end

          # popup is shown on current row
          within "table.time-card" do
            within "tr.current" do
              first("td.memo").click
              expect(page).to have_css("td.memo.focus")
            end
          end
          expect(page).to have_css('.cell-toolbar', visible: true)
          expect(page).to have_link(I18n.t("ss.links.edit"), visible: true)

          # popup is not shown on no-current row
          within "table.time-card" do
            within "tr.day-#{other_day}" do
              first("td.memo").click
              expect(page).to have_css("td.memo.focus")
            end
          end
          expect(page).to have_no_css('.cell-toolbar', visible: true)
          expect(page).to have_no_link(I18n.t("ss.links.edit"), visible: true)
        end
      end
    end
  end

  context "when user has 'use_gws_attendance_time_cards' and 'edit_gws_attendance_time_cards' permissions" do
    let!(:role) { create(:gws_role_attendance_editor) }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: [ role.id ]) }
    let(:reason1) { unique_id }
    let(:reason2) { unique_id }

    around do |example|
      travel_to(now) { example.run }
    end

    before do
      login_user user
    end

    shared_examples "time cell is punchable and editable" do
      context "cell in today row" do
        xit do
          visit gws_attendance_main_path(site)
          expect(page).to have_css(".today .info .#{cell_type}", text: '--:--')
          expect(page).to have_css("tr.current td.#{cell_type}", text: '--:--')

          # punch
          within ".today .action .#{cell_type}" do
            page.accept_confirm do
              click_on I18n.t('gws/attendance.buttons.punch')
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
          expect(page).to have_css(".today .info .#{cell_type}", text: format('%d:%02d', now.hour, now.min))
          expect(page).to have_css("tr.current td.#{cell_type}", text: format('%d:%02d', now.hour, now.min))

          # edit
          within ".today .action .#{cell_type}" do
            click_on I18n.t("ss.buttons.edit")
          end
          wait_for_cbox do
            select I18n.t('gws/attendance.hour', count: edit_at.hour), from: 'cell[in_hour]'
            select I18n.t('gws/attendance.minute', count: edit_at.min), from: 'cell[in_minute]'
            fill_in 'cell[in_reason]', with: reason1
            click_on I18n.t('ss.buttons.save')
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css(".today .info .#{cell_type}", text: format('%d:%02d', edit_at.hour, edit_at.min))
          expect(page).to have_css("tr.current td.#{cell_type}", text: format('%d:%02d', edit_at.hour, edit_at.min))
        end
      end

      context "cell in monthly table" do
        context "cell in current row" do
          xit do
            visit gws_attendance_main_path(site)
            expect(page).to have_css(".today .info .#{cell_type}", text: '--:--')
            expect(page).to have_css("tr.current td.#{cell_type}", text: '--:--')

            # punch
            within "table.time-card" do
              within "tr.current" do
                first("td.#{cell_type}").click
              end
            end
            within '.cell-toolbar' do
              page.accept_confirm do
                click_on I18n.t('gws/attendance.links.punch')
              end
            end
            expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
            expect(page).to have_css(".today .info .#{cell_type}", text: format('%d:%02d', now.hour, now.min))
            expect(page).to have_css("tr.current td.#{cell_type}", text: format('%d:%02d', now.hour, now.min))

            # edit
            within "table.time-card" do
              within "tr.current" do
                first("td.#{cell_type}").click
              end
            end
            within '.cell-toolbar' do
              click_on I18n.t("ss.buttons.edit")
            end
            wait_for_cbox do
              select I18n.t('gws/attendance.hour', count: edit_at.hour), from: 'cell[in_hour]'
              select I18n.t('gws/attendance.minute', count: edit_at.min), from: 'cell[in_minute]'
              fill_in 'cell[in_reason]', with: reason1
              click_on I18n.t('ss.buttons.save')
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            expect(page).to have_css(".today .info .#{cell_type}", text: format('%d:%02d', edit_at.hour, edit_at.min))
            expect(page).to have_css("tr.current td.#{cell_type}", text: format('%d:%02d', edit_at.hour, edit_at.min))
          end
        end

        context "cell in non-current row" do
          xit do
            visit gws_attendance_main_path(site)
            expect(page).to have_css("tr.day-#{other_day} td.#{cell_type}", text: '--:--')

            # punch
            within "table.time-card" do
              within "tr.day-#{other_day}" do
                first("td.#{cell_type}").click
              end
            end
            within '.cell-toolbar' do
              click_on I18n.t('ss.links.edit')
            end
            wait_for_cbox do
              select I18n.t('gws/attendance.hour', count: now.hour), from: 'cell[in_hour]'
              select I18n.t('gws/attendance.minute', count: now.min), from: 'cell[in_minute]'
              fill_in 'cell[in_reason]', with: reason1
              click_on I18n.t('ss.buttons.save')
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            expect(page).to have_css("tr.day-#{other_day} td.#{cell_type}", text: format('%d:%02d', now.hour, now.min))

            # edit
            within "table.time-card" do
              within "tr.day-#{other_day}" do
                first("td.#{cell_type}").click
              end
            end
            within '.cell-toolbar' do
              click_on I18n.t("ss.links.edit")
            end
            wait_for_cbox do
              select I18n.t('gws/attendance.hour', count: edit_at.hour), from: 'cell[in_hour]'
              select I18n.t('gws/attendance.minute', count: edit_at.min), from: 'cell[in_minute]'
              fill_in 'cell[in_reason]', with: reason2
              click_on I18n.t('ss.buttons.save')
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            expect(page).to have_css("tr.day-#{other_day} td.#{cell_type}", text: format('%d:%02d', edit_at.hour, edit_at.min))
          end
        end
      end
    end

    context "with enter" do
      let(:cell_type) { "enter" }
      include_context "time cell is punchable and editable"
    end

    context "with leave" do
      let(:cell_type) { "leave" }
      include_context "time cell is punchable and editable"
    end

    context "with break_enter2" do
      let(:cell_type) { "break_enter2" }
      include_context "time cell is punchable and editable"
    end

    context 'with break_leave3' do
      let(:cell_type) { "break_leave3" }
      include_context "time cell is punchable and editable"
    end

    context 'with memo' do
      let(:memo1) { unique_id }
      let(:memo2) { unique_id }

      context "cell in today row" do
        xit do
          visit gws_attendance_main_path(site)
          expect(page).to have_css(".today .info .memo", text: '')
          expect(page).to have_css("tr.current td.memo", text: '')

          # create new memo
          within ".today .action .memo" do
            click_on I18n.t("ss.buttons.edit")
          end
          wait_for_cbox do
            fill_in 'record[memo]', with: memo1
            click_on I18n.t('ss.buttons.save')
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css(".today .info .memo", text: memo1)
          expect(page).to have_css("tr.current td.memo", text: memo1)

          # edit
          within ".today .action .memo" do
            click_on I18n.t("ss.buttons.edit")
          end
          wait_for_cbox do
            fill_in 'record[memo]', with: memo2
            click_on I18n.t('ss.buttons.save')
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(page).to have_css(".today .info .memo", text: memo2)
          expect(page).to have_css("tr.current td.memo", text: memo2)
        end
      end

      context "cell in monthly table" do
        context "cell in current row" do
          xit do
            visit gws_attendance_main_path(site)
            expect(page).to have_css(".today .info .memo", text: '')
            expect(page).to have_css("tr.current td.memo", text: '')

            # create new memo
            within "table.time-card" do
              within "tr.current" do
                first("td.memo").click
              end
            end
            within '.cell-toolbar' do
              click_on I18n.t("ss.links.edit")
            end
            wait_for_cbox do
              fill_in 'record[memo]', with: memo1
              click_on I18n.t('ss.buttons.save')
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            expect(page).to have_css(".today .info .memo", text: memo1)
            expect(page).to have_css("tr.current td.memo", text: memo1)

            # edit
            within "table.time-card" do
              within "tr.current" do
                first("td.memo").click
              end
            end
            within '.cell-toolbar' do
              click_on I18n.t("ss.links.edit")
            end
            wait_for_cbox do
              fill_in 'record[memo]', with: memo2
              click_on I18n.t('ss.buttons.save')
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            expect(page).to have_css(".today .info .memo", text: memo2)
            expect(page).to have_css("tr.current td.memo", text: memo2)
          end
        end

        context "cell in non-current row" do
          xit do
            visit gws_attendance_main_path(site)
            expect(page).to have_css("tr.day-#{other_day} td.memo", text: '')

            # create new memo
            within "table.time-card" do
              within "tr.day-#{other_day}" do
                first("td.memo").click
              end
            end
            within '.cell-toolbar' do
              click_on I18n.t('ss.links.edit')
            end
            wait_for_cbox do
              fill_in 'record[memo]', with: memo1
              click_on I18n.t('ss.buttons.save')
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            expect(page).to have_css("tr.day-#{other_day} td.memo", text: memo1)

            # edit
            within "table.time-card" do
              within "tr.day-#{other_day}" do
                first("td.memo").click
              end
            end
            within '.cell-toolbar' do
              click_on I18n.t("ss.links.edit")
            end
            wait_for_cbox do
              fill_in 'record[memo]', with: memo2
              click_on I18n.t('ss.buttons.save')
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            expect(page).to have_css("tr.day-#{other_day} td.memo", text: memo2)
          end
        end
      end
    end
  end
end
