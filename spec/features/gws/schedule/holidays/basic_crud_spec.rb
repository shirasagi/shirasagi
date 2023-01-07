require 'spec_helper'

describe "gws_schedule_holidays", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_schedule_holidays_path site }
  let(:item) { create :gws_schedule_holiday }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#new" do
      visit "#{index_path}/new"
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in_date "item[start_on]", with: "2016/01/01"
        fill_in_date "item[end_on]", with: "2016/01/02"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(current_path).to eq index_path
    end

    it "#show" do
      visit "#{index_path}/#{item.id}"
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit "#{index_path}/#{item.id}/edit"
      within "form#item-form" do
        fill_in "item[name]", with: "name2"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(current_path).to eq index_path
    end

    it "#delete" do
      visit "#{index_path}/#{item.id}/delete"
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(current_path).to eq index_path
    end
  end
end

describe "gws_schedule_holidays", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_schedule_holidays_path site }
  let(:item) { create :gws_schedule_holiday }
  let(:import_path) { import_gws_schedule_holidays_path site.id }
  let(:download_path) { download_gws_schedule_holidays_path site.id }

  before { login_gws_user }

  describe "#import" do
    before { visit import_path }
    context "when the all datas on csv is valid" do
      it "imported the datas" do
        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/schedule/gws_holidays_1.csv"
          click_button I18n.t('ss.links.import')
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        not_repeat = Gws::Schedule::Holiday.site(site).where(name: "not_repeat").first
        repeat = Gws::Schedule::Holiday.site(site).where(name: "repeat").first

        expect(not_repeat).to be_valid
        expect(not_repeat.start_on).to eq Date.strptime('2019/1/1', '%Y/%m/%d')
        expect(not_repeat.end_on).to eq Date.strptime('2019/1/3', '%Y/%m/%d')
        expect(not_repeat.color).to eq "#99dd66"
        expect(not_repeat.repeat_plan).to be_nil

        expect(repeat).to be_valid
        expect(repeat.start_on).to eq Date.strptime('2019/2/1', '%Y/%m/%d')
        expect(repeat.end_on).to eq Date.strptime('2019/2/2', '%Y/%m/%d')
        expect(repeat.color).to eq "#99dd50"
        expect(repeat.repeat_plan.repeat_type).to eq "weekly"
        expect(repeat.repeat_plan.interval).to eq 1
        expect(repeat.repeat_plan.repeat_start).to eq Date.strptime('2019/2/1', '%Y/%m/%d')
        expect(repeat.repeat_plan.repeat_end).to eq Date.strptime('2019/3/1', '%Y/%m/%d')
        expect(repeat.repeat_plan.wdays).to eq []
        expect(repeat.repeat_plan.repeat_base).to eq "date"
      end
    end

    context "when some data on csv is invalid" do
      it "does not import the only data on CSVfile" do
        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/schedule/gws_holidays_2.csv"
          click_button I18n.t('ss.links.import')
        end
        expect(page).to have_http_status(200)
        holidays = Gws::Schedule::Holiday.site(site)
        valid_holiday = Gws::Schedule::Holiday.site(site).where(name: "valid").first
        expect(holidays.size).to eq 1
        expect(holidays).to include valid_holiday
        expect(holidays.map(&:name)).not_to include "invalid"
      end
    end
  end

  describe "#download" do
    before do
      item
      visit index_path
    end
    let(:time){ Time.zone.now }
    it "downloads CSVfile" do
      Timecop.freeze(time) do
        click_link I18n.t('ss.links.download')
        expect(status_code).to eq 200
        expect(page.response_headers['Content-Type']).to eq("text/csv")

        filename = "gws_holidays_#{time.to_i}.csv"
        disposition = ActionDispatch::Http::ContentDisposition.format(disposition: "attachment", filename: filename)
        expect(page.response_headers['Content-Disposition']).to eq disposition
      end

      I18n.with_locale(I18n.default_locale) do
        csv = CSV.parse(page.html.encode("UTF-8", "SJIS"), headers: true)
        expect(csv.headers.include?(I18n.t("gws/schedule.csv.id"))).to be_truthy
        expect(csv.headers.include?(I18n.t("gws/schedule.csv.name"))).to be_truthy
        expect(csv.headers.include?(I18n.t("gws/schedule.csv.start_on"))).to be_truthy
        expect(csv.headers.include?(I18n.t("gws/schedule.csv.end_on"))).to be_truthy
        expect(csv.headers.include?(I18n.t("gws/schedule.csv.repeat_plan_datas.repeat_type"))).to be_truthy
        expect(csv.headers.include?(I18n.t("gws/schedule.csv.repeat_plan_datas.repeat_start"))).to be_truthy
      end
    end
  end
end
