require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.change(day: 9, hour: 9).beginning_of_minute }
  let(:reason) { unique_id }
  let(:memo) { unique_id }

  before do
    login_gws_user

    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  shared_examples "edit time cell" do
    around do |example|
      travel_to(now) { example.run }
    end

    before do
      # punch
      visit gws_attendance_main_path(site)
      expect(page).to have_css(".today .info .#{cell_type}", text: '--:--')

      within ".today .action .#{cell_type}" do
        page.accept_confirm do
          click_on I18n.t('gws/attendance.buttons.punch')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
      expect(page).to have_css(".today .info .#{cell_type}", text: format('%d:%02d', now.hour, now.min))

      expect(Gws::Attendance::TimeCard.count).to eq 1
      Gws::Attendance::TimeCard.first.tap do |time_card|
        expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
        time_card.records.where(date: now.beginning_of_day).first.tap do |record|
          expect(record.send(cell_type)).to eq now
        end
      end
    end

    context "edit cell in today row" do
      it do
        # edit
        within ".today .action .#{cell_type}" do
          click_on I18n.t('ss.buttons.edit')
        end
        wait_for_cbox do
          select I18n.t("gws/attendance.hour", count: 8), from: 'cell[in_hour]'
          select I18n.t("gws/attendance.minute", count: 32), from: 'cell[in_minute]'
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css(".today .info .#{cell_type}", text: '8:32')
        expect(page).to have_css("tr.current td.#{cell_type}", text: '8:32')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.send(cell_type)).to eq now.change(hour: 8, min: 32)
          end
        end

        # clear
        within ".today .action .#{cell_type}" do
          click_on I18n.t('ss.buttons.edit')
        end
        wait_for_cbox do
          click_on I18n.t('ss.buttons.clear')
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css(".today .info .#{cell_type}", text: '--:--')
        expect(page).to have_css("tr.current td.#{cell_type}", text: '--:--')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.send(cell_type)).to be_nil
          end
        end
      end
    end

    context "edit in monthly table" do
      it do
        # edit
        within "table.time-card" do
          within "tr.current" do
            first("td.#{cell_type}").click
          end
        end
        within '.cell-toolbar' do
          click_on I18n.t('ss.buttons.edit')
        end
        wait_for_cbox do
          select I18n.t("gws/attendance.hour", count: 8), from: 'cell[in_hour]'
          select I18n.t("gws/attendance.minute", count: 32), from: 'cell[in_minute]'
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css(".today .info .#{cell_type}", text: '8:32')
        expect(page).to have_css("tr.current td.#{cell_type}", text: '8:32')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.send(cell_type)).to eq now.change(hour: 8, min: 32)
          end
        end

        # clear
        within "table.time-card" do
          within "tr.current" do
            first("td.#{cell_type}").click
          end
        end
        within '.cell-toolbar' do
          click_on I18n.t('ss.buttons.edit')
        end
        wait_for_cbox do
          click_on I18n.t('ss.buttons.clear')
          fill_in 'cell[in_reason]', with: reason
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css(".today .info .#{cell_type}", text: '--:--')
        expect(page).to have_css("tr.current td.#{cell_type}", text: '--:--')

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.send(cell_type)).to be_nil
          end
        end
      end
    end
  end

  context 'edit enter' do
    let(:cell_type) { "enter" }
    include_context "edit time cell"

    context "when reason remains blank" do
      it do
        within "table.time-card" do
          within "tr.current" do
            first("td.#{cell_type}").click
          end
        end
        within '.cell-toolbar' do
          click_on I18n.t('ss.buttons.edit')
        end
        wait_for_cbox do
          select I18n.t("gws/attendance.hour", count: 8), from: 'cell[in_hour]'
          select I18n.t("gws/attendance.minute", count: 32), from: 'cell[in_minute]'
          click_on I18n.t('ss.buttons.save')
        end

        within "#cboxLoadedContent form.cell-edit" do
          error = I18n.t(
            "errors.format",
            attribute: I18n.t("activemodel.attributes.gws/attendance/time_edit.in_reason"),
            message: I18n.t("errors.messages.blank")
          )
          expect(page).to have_css("#errorExplanation", text: error)
        end
      end
    end
  end

  context 'edit leave' do
    let(:cell_type) { "leave" }
    include_context "edit time cell"
  end

  context 'edit break_enter1' do
    let(:cell_type) { "break_enter1" }
    include_context "edit time cell"
  end

  context 'edit break_leave1' do
    let(:cell_type) { "break_leave1" }
    include_context "edit time cell"
  end

  context 'edit break_enter2' do
    let(:cell_type) { "break_enter2" }
    include_context "edit time cell"
  end

  context 'edit break_leave2' do
    let(:cell_type) { "break_leave2" }
    include_context "edit time cell"
  end

  context 'edit break_enter3' do
    let(:cell_type) { "break_enter3" }
    include_context "edit time cell"
  end

  context 'edit break_leave3' do
    let(:cell_type) { "break_leave3" }
    include_context "edit time cell"
  end

  context 'edit memo' do
    around do |example|
      travel_to(now) { example.run }
    end

    context "edit cell in today row" do
      it do
        visit gws_attendance_main_path(site)
        within '.today .action .memo' do
          click_on I18n.t('ss.buttons.edit')
        end
        wait_for_cbox do
          fill_in 'record[memo]', with: memo
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('.today .info .memo', text: memo)
        expect(page).to have_css('tr.current td.memo', text: memo)

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.memo).to eq memo
          end
        end
      end
    end

    context "edit in monthly table" do
      it do
        visit gws_attendance_main_path(site)

        within "table.time-card" do
          within "tr.current" do
            first("td.memo").click
          end
        end
        within '.cell-toolbar' do
          click_on I18n.t('ss.buttons.edit')
        end
        wait_for_cbox do
          fill_in 'record[memo]', with: memo
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('.today .info .memo', text: memo)
        expect(page).to have_css('tr.current td.memo', text: memo)

        expect(Gws::Attendance::TimeCard.count).to eq 1
        Gws::Attendance::TimeCard.first.tap do |time_card|
          expect(time_card.records.where(date: now.beginning_of_day).count).to eq 1
          time_card.records.where(date: now.beginning_of_day).first.tap do |record|
            expect(record.memo).to eq memo
          end
        end
      end
    end
  end
end
