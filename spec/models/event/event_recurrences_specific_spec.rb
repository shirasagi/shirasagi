require 'spec_helper'

describe Event::Page, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :event_node_page, cur_site: site }
  let!(:item) do
    page = create(:event_page, cur_site: site, cur_node: node, event_recurrences: [ recurr3, recurr2, recurr1, duplicated_recurr ])
    Event::Page.find(page.id)
  end
  let!(:specifics) { item.collect_event_date_specifics }

  let!(:day1) { Time.zone.today }
  let!(:day2) { day1 + 1.day }
  let!(:day3) { day2 + 1.day }

  # day1 12:00 - 13:00
  # day2 12:00 - 13:00, 14:00 - 15:00
  # day3 allday (12:00 - 13:00, 14:00 - 15:00)

  let(:recurr1) do
    { kind: "datetime", start_at: day1.in_time_zone.change(hour: 12), end_at: day1.in_time_zone.change(hour: 13), frequency: "daily", until_on: day3 }
  end
  let(:recurr2) do
    { kind: "datetime", start_at: day2.in_time_zone.change(hour: 14), end_at: day2.in_time_zone.change(hour: 15), frequency: "daily", until_on: day3 }
  end
  let(:recurr3) do
    { kind: "date", start_at: day3, frequency: "daily", until_on: day3 }
  end
  let(:duplicated_recurr) do
    { kind: "datetime", start_at: day1.in_time_zone.change(hour: 12), end_at: day1.in_time_zone.change(hour: 13), frequency: "daily", until_on: day1 }
  end

  let(:specific1) do
    Event::Extensions::Recurrence::Specific.new(
      kind: "datetime",
      date: day1,
      start_at: day1.in_time_zone.change(hour: 12),
      end_at: day1.in_time_zone.change(hour: 13))
  end
  let(:specific2_1) do
    Event::Extensions::Recurrence::Specific.new(
      kind: "datetime",
      date: day2,
      start_at: day2.in_time_zone.change(hour: 12),
      end_at: day2.in_time_zone.change(hour: 13))
  end
  let(:specific2_2) do
    Event::Extensions::Recurrence::Specific.new(
      kind: "datetime",
      date: day2,
      start_at: day2.in_time_zone.change(hour: 14),
      end_at: day2.in_time_zone.change(hour: 15))
  end
  let(:specific3) do
    Event::Extensions::Recurrence::Specific.new(
      kind: "date",
      date: day3)
  end

  it "#collect_event_date_specifics" do
    expect(specifics.keys).to eq [day1, day2, day3]

    # day1
    expect(specifics[day1].count).to eq 1
    expect(specifics[day1][0]).to eq specific1

    # day2
    expect(specifics[day2].count).to eq 2
    expect(specifics[day2][0]).to eq specific2_2
    expect(specifics[day2][1]).to eq specific2_1

    specifics[day2].sort!
    expect(specifics[day2][0]).to eq specific2_1
    expect(specifics[day2][1]).to eq specific2_2

    # day3
    expect(specifics[day3].count).to eq 1
    expect(specifics[day3][0]).to eq specific3
  end
end
