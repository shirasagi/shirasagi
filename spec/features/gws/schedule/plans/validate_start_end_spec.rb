require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:item) { create :gws_schedule_plan }
  let(:index_path) { gws_schedule_plans_path site }
  let(:edit_path) { edit_gws_schedule_plan_path site, item }

  let(:model) { Gws::Schedule::Plan }
  let(:datetime_message) do
    message = I18n.t("errors.messages.greater_than", count: model.t(:start_at))
    I18n.t("errors.format", attribute: model.t(:end_at), message: message)
  end
  let(:date_message) do
    message = I18n.t("errors.messages.greater_than", count: model.t(:start_on))
    I18n.t("errors.format", attribute: model.t(:end_on), message: message)
  end

  def format_picker(datetime)
    datetime.strftime(format)
  end

  context "validate datetime" do
    let(:format) { I18n.t("time.formats.picker") }
    let!(:now) { Time.zone.now }
    let!(:day_ago) { now.advance(days: -1) }
    let!(:day_later) { now.advance(days: 1) }

    let(:start_at) { model.last.start_at }
    let(:end_at) { model.last.end_at }

    before { login_gws_user }

    it "# new" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in "item[start_at]", with: format_picker(now)
        fill_in "item[end_at]", with: format_picker(now)
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq index_path
      within "#errorExplanation" do
        expect(page).to have_text(datetime_message)
        expect(page).to have_no_text(date_message)
      end
    end

    it "# new" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in "item[start_at]", with: format_picker(now)
        fill_in "item[end_at]", with: format_picker(day_later)
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq index_path
      expect(format_picker(start_at)).to eq format_picker(now)
      expect(format_picker(end_at)).to eq format_picker(day_later)
    end

    it "# new" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in "item[start_at]", with: format_picker(now)
        fill_in "item[end_at]", with: format_picker(day_ago)
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq index_path
      within "#errorExplanation" do
        expect(page).to have_text(datetime_message)
        expect(page).to have_no_text(date_message)
      end
    end
  end

  context "validate date" do
    let(:format) { I18n.t("date.formats.picker") }
    let!(:now) { Time.zone.now }
    let!(:day_ago) { now.advance(days: -1) }
    let!(:day_later) { now.advance(days: 1) }

    let(:start_on) { model.last.start_on }
    let(:end_on) { model.last.end_on }

    before { login_gws_user }

    it "# new" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        check "item_allday"
        fill_in "item[start_on]", with: format_picker(now)
        fill_in "item[end_on]", with: format_picker(now)
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq index_path
      expect(format_picker(start_on)).to eq format_picker(now)
      expect(format_picker(end_on)).to eq format_picker(now)
    end

    it "# new" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        check "item_allday"
        fill_in "item[start_on]", with: format_picker(now)
        fill_in "item[end_on]", with: format_picker(day_later)
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq index_path
      expect(format_picker(start_on)).to eq format_picker(now)
      expect(format_picker(end_on)).to eq format_picker(day_later)
    end

    it "# new" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        check "item_allday"
        fill_in "item[start_on]", with: format_picker(now)
        fill_in "item[end_on]", with: format_picker(day_ago)
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq index_path
      within "#errorExplanation" do
        expect(page).to have_no_text(datetime_message)
        expect(page).to have_text(date_message)
      end
    end
  end
end
