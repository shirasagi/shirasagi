require 'spec_helper'

describe Event::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :event_node_page, cur_site: site }
  subject { create :event_page, cur_site: site, cur_node: node }
  let(:show_path) { Rails.application.routes.url_helpers.event_page_path(site: subject.site, cid: subject.parent, id: subject) }

  describe "#attributes" do
    it { expect(subject.becomes_with_route).not_to eq nil }
    it { expect(subject.dirname).not_to eq nil }
    it { expect(subject.basename).not_to eq nil }
    it { expect(subject.path).not_to eq nil }
    it { expect(subject.url).not_to eq nil }
    it { expect(subject.full_url).not_to eq nil }
    it { expect(subject.parent).to eq node }
    it { expect(subject.private_show_path).to eq show_path }
  end

  describe ".search" do
    # context "when categories is given" do
    #   subject { described_class.search(categories: ["151"]) }
    #   it { expect(subject.selector.to_h).to include("$or" => [{"category_ids"=>151}]) }
    # end
    #
    # context "when categories is given" do
    #   subject { described_class.search(categories: %w(151 152)) }
    #   it { expect(subject.selector.to_h).to include("$or" => [{"category_ids"=>151}, {"category_ids"=>152}]) }
    # end

    context "when dates is given" do
      let(:today) { Time.zone.today }
      subject { described_class.search(dates: [today]) }
      it { expect(subject.selector.to_h).to include("event_dates" => {"$gte" => today, "$lte" => today}) }
    end

    context "when dates is given 3 dates" do
      let(:day1) { Time.zone.today }
      let(:day2) { day1 + 1 }
      let(:day3) { day1 + 2 }
      let(:days) { [ day1, day2, day3 ] }

      subject { described_class.search(dates: days) }
      it do
        expect(subject.selector.to_h).to include(
          "event_dates" => {"$gte" => days.first, "$lte" => days.last}
        )
      end
    end

    context "when dates is given range of dates" do
      let(:day1) { Time.zone.today }
      let(:day2) { day1 + 2 }
      let(:days) { day1..day2 }

      subject { described_class.search(dates: days) }
      it do
        expect(subject.selector.to_h).to include(
          "event_dates" => {"$gte" => days.first, "$lte" => days.last}
        )
      end
    end

    context "when dates start_date is balnk" do
      subject { described_class.search(close_date: Time.zone.today.to_s) }
      it { expect(subject.selector.to_h).to include("event_dates" => {"$lte"=>Time.zone.today.to_s})}

    end

    context "when dates close_date is balnk" do
      subject { described_class.search(start_date: Time.zone.today.to_s) }
      it { expect(subject.selector.to_h).to include("event_dates" => {"$gte"=>Time.zone.today.to_s})}
    end
  end
end
