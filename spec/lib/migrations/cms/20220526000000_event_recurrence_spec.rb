require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20220526000000_event_recurrence.rb")

RSpec.describe SS::Migration20220526000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:page1) { create :cms_page, cur_site: site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:page2) { create :cms_page, cur_site: site, cur_node: node }
  let(:event_dates) do
    %w(2022/05/27 2022/05/28 2022/05/29 2022/06/03 2022/06/04 2022/06/05).map do |event_date|
      event_date.in_time_zone.to_date
    end
  end
  let!(:page3_single_event_date) { create :cms_page, cur_site: site, cur_node: node }
  let!(:page4_event_dates_nil) do
    page = create :cms_page, cur_site: site, cur_node: node
    page.collection.update_one({ _id: page.id }, { '$set' => { event_dates: nil } })
    page.unset(:event_recurrences)
    Cms::Page.find(page.id)
  end

  before do
    page1.set(event_dates: event_dates)
    page2.set(event_dates: event_dates)
    page3_single_event_date.set(event_dates: [ event_dates[3] ])
    expect(page4_event_dates_nil.attributes.key?(:event_dates)).to be_truthy
    expect(page4_event_dates_nil.event_dates).to be_nil

    described_class.new.change
  end

  it do
    page1.reload
    expect(page1.event_dates).to eq event_dates
    expect(page1.event_recurrences).to have(2).items
    page1.event_recurrences[0].tap do |event_recurrence|
      expect(event_recurrence.kind).to eq "date"
      expect(event_recurrence.start_at).to eq "2022/05/27".in_time_zone.to_date
      expect(event_recurrence.frequency).to eq "daily"
      expect(event_recurrence.until_on).to eq "2022/05/29".in_time_zone.to_date
      expect(event_recurrence.end_at).to eq "2022/05/28".in_time_zone.to_date
      expect(event_recurrence.by_days).to be_blank
      expect(event_recurrence.includes_holiday).to be_falsey
      expect(event_recurrence.exclude_dates).to be_blank
    end
    page1.event_recurrences[1].tap do |event_recurrence|
      expect(event_recurrence.kind).to eq "date"
      expect(event_recurrence.start_at).to eq "2022/06/03".in_time_zone.to_date
      expect(event_recurrence.frequency).to eq "daily"
      expect(event_recurrence.until_on).to eq "2022/06/05".in_time_zone.to_date
      expect(event_recurrence.end_at).to eq "2022/06/04".in_time_zone.to_date
      expect(event_recurrence.by_days).to be_blank
      expect(event_recurrence.includes_holiday).to be_falsey
      expect(event_recurrence.exclude_dates).to be_blank
    end

    page2.reload
    expect(page2.event_dates).to eq event_dates
    expect(page2.event_recurrences).to have(2).items
    page2.event_recurrences[0].tap do |event_recurrence|
      expect(event_recurrence.kind).to eq "date"
      expect(event_recurrence.start_at).to eq "2022/05/27".in_time_zone.to_date
      expect(event_recurrence.frequency).to eq "daily"
      expect(event_recurrence.until_on).to eq "2022/05/29".in_time_zone.to_date
      expect(event_recurrence.end_at).to eq "2022/05/28".in_time_zone.to_date
      expect(event_recurrence.by_days).to be_blank
      expect(event_recurrence.includes_holiday).to be_falsey
      expect(event_recurrence.exclude_dates).to be_blank
    end
    page2.event_recurrences[1].tap do |event_recurrence|
      expect(event_recurrence.kind).to eq "date"
      expect(event_recurrence.start_at).to eq "2022/06/03".in_time_zone.to_date
      expect(event_recurrence.frequency).to eq "daily"
      expect(event_recurrence.until_on).to eq "2022/06/05".in_time_zone.to_date
      expect(event_recurrence.end_at).to eq "2022/06/04".in_time_zone.to_date
      expect(event_recurrence.by_days).to be_blank
      expect(event_recurrence.includes_holiday).to be_falsey
      expect(event_recurrence.exclude_dates).to be_blank
    end

    page3_single_event_date.reload
    expect(page3_single_event_date.event_dates).to eq [ event_dates[3] ]
    expect(page3_single_event_date.event_recurrences).to have(1).items
    page3_single_event_date.event_recurrences[0].tap do |event_recurrence|
      expect(event_recurrence.kind).to eq "date"
      expect(event_recurrence.start_at).to eq "2022/06/03".in_time_zone.to_date
      expect(event_recurrence.frequency).to eq "daily"
      expect(event_recurrence.until_on).to eq "2022/06/03".in_time_zone.to_date
      expect(event_recurrence.end_at).to eq "2022/06/04".in_time_zone.to_date
      expect(event_recurrence.by_days).to be_blank
      expect(event_recurrence.includes_holiday).to be_falsey
      expect(event_recurrence.exclude_dates).to be_blank
    end

    Cms::Page.find(page4_event_dates_nil.id).tap do |page|
      expect(page.attributes.key?(:event_dates)).to be_falsey
      expect(page.event_dates).to be_nil
    end
  end
end
