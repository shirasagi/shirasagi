require 'spec_helper'

describe Gws::Schedule::PlanHelper, type: :helper, dbscope: :example do
  before do
    helper.instance_variable_set :@cur_user, gws_user
    helper.instance_variable_set :@cur_site, gws_site
  end

  describe "term" do
    let(:item) { create :gws_schedule_plan }

    it "same allday" do
      item.allday   = 'allday'
      item.start_at = '2016-01-01 00:00:00'
      item.end_at   = '2016-01-01 00:00:00'
      term = helper.term(item)
      expect(term).to eq I18n.l(item.start_at.to_date, format: :gws_long)
    end

    it "different allday" do
      item.allday   = 'allday'
      item.start_at = '2016-01-01 00:00:00'
      item.end_at   = '2016-01-02 00:00:00'
      term = helper.term(item)
      expect(term).to include I18n.l(item.start_at.to_date, format: :gws_long)
      expect(term).not_to include I18n.l(item.end_at.to_date, format: :gws_long)
    end

    it "same timestamp" do
      item.start_at = '2016-01-01 00:00:00'
      item.end_at   = '2016-01-01 00:00:00'
      term = helper.term(item)
      expect(term).to eq I18n.l(item.start_at, format: :gws_long)
    end

    it "different hour" do
      item.start_at = '2016-01-01 00:00:00'
      item.end_at   = '2016-01-01 01:00:00'
      term = helper.term(item)
      expect(term).to include I18n.l(item.start_at, format: :gws_long)
      expect(term).not_to include I18n.l(item.end_at, format: :gws_long)
    end

    it "different day" do
      item.start_at = '2016-01-01 00:00:00'
      item.end_at   = '2016-01-02 00:00:00'
      term = helper.term(item)
      expect(term).to include I18n.l(item.start_at, format: :gws_long)
      expect(term).not_to include I18n.l(item.end_at, format: :gws_long)
    end

    it "different month" do
      item.start_at = '2016-01-01 00:00:00'
      item.end_at   = '2016-02-01 00:00:00'
      term = helper.term(item)
      expect(term).to include I18n.l(item.start_at, format: :gws_long)
      expect(term).not_to include I18n.l(item.end_at, format: :gws_long)
    end

    it "different year" do
      item.start_at = '2016-01-01 00:00:00'
      item.end_at   = '2017-01-01 00:00:00'
      term = helper.term(item)
      expect(term).to include I18n.l(item.start_at, format: :gws_long)
      expect(term).to include I18n.l(item.end_at, format: :gws_long)
    end
  end

  describe "calendar_format" do
    let!(:item) { create :gws_schedule_plan }

    it "events" do
      plans  = Gws::Schedule::Plan.all
      events = helper.calendar_format(plans)
      expect(events.present?).to eq true
    end
  end

  describe "group_holidays" do
    let!(:item) { create :gws_schedule_holiday, start_on: '2016-01-01', end_on: '2016-01-01' }

    it "events" do
      start_at = Date.parse('2016-01-01')
      end_at   = Date.parse('2016-02-01')
      events   = helper.group_holidays(start_at, end_at)
      expect(events.size).to eq 1
    end
  end

  describe "calendar_holidays" do
    it "events" do
      start_at = Date.parse('2016-01-01')
      end_at   = Date.parse('2016-02-01')
      events   = helper.calendar_holidays(start_at, end_at)
      expect(events.size).to eq 2
    end
  end
end
