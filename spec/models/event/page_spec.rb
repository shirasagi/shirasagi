require 'spec_helper'

describe Event::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :event_node_page, cur_site: site }
  let(:event_date) { Time.zone.now.beginning_of_day + rand(1..10).days }
  let(:event_recurrence) do
    { kind: "date", start_at: event_date, frequency: "daily", until_on: event_date }
  end
  subject { create :event_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurrence ] }
  let(:show_path) { Rails.application.routes.url_helpers.event_page_path(site: subject.site, cid: subject.parent, id: subject) }

  describe "#attributes" do
    it { expect(subject.dirname).to eq node.filename }
    it { expect(subject.basename).not_to eq nil }
    it { expect(subject.path).not_to eq nil }
    it { expect(subject.url).not_to eq nil }
    it { expect(subject.full_url).not_to eq nil }
    it { expect(subject.parent).to eq node }
    it { expect(subject.private_show_path).to eq show_path }
    it do
      subject.reload

      event_dates = subject.read_attribute_before_type_cast(:event_dates)
      expect(event_dates).to have(1).items
      expect(event_dates.first.in_time_zone).not_to eq event_date
      expect(event_dates.first.in_time_zone).to eq event_date + event_date.utc_offset.seconds
    end
  end

  describe "validation" do
    let(:site_limit0) { create :cms_site_unique, max_name_length: 0 }
    let(:site_limit80) { create :cms_site_unique, max_name_length: 80 }

    it "basename" do
      item = build(:event_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end

    it "name with limit 0" do
      item = build(:event_page_10_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:event_page_100_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:event_page_1000_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy
    end

    it "name with limit 80" do
      item = build(:event_page_10_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_truthy

      item = build(:event_page_100_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey

      item = build(:event_page_1000_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey
    end
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
      it { expect(subject.selector.to_h).to include("event_dates" => {"$lte"=>Time.zone.today.to_s}) }

    end

    context "when dates close_date is balnk" do
      subject { described_class.search(start_date: Time.zone.today.to_s) }
      it { expect(subject.selector.to_h).to include("event_dates" => {"$gte"=>Time.zone.today.to_s}) }
    end
  end

  describe ".new_size_input" do
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:file) do
      SS::File.create_empty!(
        cur_user: cms_user, site_id: cms_site.id, model: "event/page", filename: "logo.png", content_type: 'image/png'
      ) do |file|
        FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
      end
    end
    let!(:column1) { create(:cms_column_free, cur_form: form, order: 1) }
    let!(:column2) { create(:cms_column_file_upload, cur_form: form, order: 1, file_type: 'image', html_tag: "a+img") }
    let!(:html_size) { html.bytesize }
    let!(:file_size) { File.size(file.path) }

    context "with html only" do
      let!(:html) { "<h1>SHIRASAGI</h1>" }
      let!(:item) { create :event_page, cur_node: node, html: html }

      it do
        expect(item.size).to eq html_size
      end
    end

    context "with file only" do
      let!(:item) { create :event_page, cur_node: node, file_ids: [file.id] }
      it do
        expect(item.size).to eq file_size
      end
    end

    context "with html and file" do
      let!(:html) { "<h1>SHIRASAGI</h1>" }
      let!(:item) { create :event_page, cur_node: node, html: html, file_ids: [file.id] }

      it do
        expect(item.size).to eq html_size + file_size
      end
    end

  end

end
