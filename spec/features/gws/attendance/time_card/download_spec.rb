require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now }
  let(:this_month) { now.beginning_of_month }
  let(:prev_month) { this_month - 1.month }
  let(:next_month) { this_month + 1.month }
  let!(:time_card_this_month) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user, date: this_month
  end
  let!(:time_card_prev_month) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user, date: prev_month
  end
  let!(:time_card_next_month) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user, date: next_month
  end

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  before { login_user user }

  describe 'download' do
    context "with default params" do
      xit do
        visit gws_attendance_main_path(site)

        within ".nav-operation" do
          click_on I18n.t("ss.buttons.download")
        end

        within "form#item-form" do
          click_on I18n.t("ss.buttons.download")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true)
          expect(csv.length).to eq this_month.end_of_month.day
          expect(csv[0][0]).to eq user.uid
          expect(csv[0][1]).to eq user.name
          expect(csv[0][2]).to eq this_month.to_date.iso8601
        end
      end
    end

    context "with Shift_JIS" do
      xit do
        visit gws_attendance_main_path(site)

        within ".nav-operation" do
          click_on I18n.t("ss.buttons.download")
        end

        within "form#item-form" do
          # choose
          first("input[value='Shift_JIS']").click
          click_on I18n.t("ss.buttons.download")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
          expect(csv.length).to eq this_month.end_of_month.day
          expect(csv[0][0]).to eq user.uid
          expect(csv[0][1]).to eq user.name
          expect(csv[0][2]).to eq this_month.to_date.iso8601
        end
      end
    end

    context "with UTF-8" do
      xit do
        visit gws_attendance_main_path(site)

        within ".nav-operation" do
          click_on I18n.t("ss.buttons.download")
        end

        within "form#item-form" do
          # choose
          first("input[value='UTF-8']").click
          click_on I18n.t("ss.buttons.download")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true)
          expect(csv.length).to eq this_month.end_of_month.day
          expect(csv[0][0]).to eq user.uid
          expect(csv[0][1]).to eq user.name
          expect(csv[0][2]).to eq this_month.to_date.iso8601
        end
      end
    end
  end
end
