require 'spec_helper'

RSpec.describe Gws::Schedule::RepeatPlan, type: :model, dbscope: :example, tmpdir: true do
  let(:sunday) { 0 }
  let(:monday) { 1 }
  let(:tuesday) { 2 }
  let(:wednesday) { 3 }
  let(:thursday) { 4 }
  let(:friday) { 5 }
  let(:saturday) { 6 }

  describe "#monthly_dates_by_date" do
    context "with 2016/05/01～2017/5/01" do
      let(:repeat_start) { Date.new(2016, 5, 1) }
      let(:repeat_end) { Date.new(2017, 5, 1) }
      let(:interval) { 1 }
      let(:item) { described_class.new(repeat_start: repeat_start, repeat_end: repeat_end, interval: 1) }
      subject { item.send(:monthly_dates_by_date) }

      it { is_expected.to include(Date.new(2016, 5, 1)) }
      it { is_expected.to include(Date.new(2016, 6, 1)) }
      it { is_expected.to include(Date.new(2016, 7, 1)) }
      it { is_expected.to include(Date.new(2016, 8, 1)) }
      it { is_expected.to include(Date.new(2016, 9, 1)) }
      it { is_expected.to include(Date.new(2016, 10, 1)) }
      it { is_expected.to include(Date.new(2016, 11, 1)) }
      it { is_expected.to include(Date.new(2016, 12, 1)) }
      it { is_expected.to include(Date.new(2017, 1, 1)) }
      it { is_expected.to include(Date.new(2017, 2, 1)) }
      it { is_expected.to include(Date.new(2017, 3, 1)) }
      it { is_expected.to include(Date.new(2017, 4, 1)) }
    end

    context "with 2016/05/31～2017/5/31" do
      let(:repeat_start) { Date.new(2016, 5, 31) }
      let(:repeat_end) { Date.new(2017, 5, 31) }
      let(:interval) { 1 }
      let(:item) { described_class.new(repeat_start: repeat_start, repeat_end: repeat_end, interval: 1) }
      subject { item.send(:monthly_dates_by_date) }

      it { is_expected.to include(Date.new(2016, 5, 31)) }
      it { is_expected.to include(Date.new(2016, 6, 30)) }
      it { is_expected.to include(Date.new(2016, 7, 31)) }
      it { is_expected.to include(Date.new(2016, 8, 31)) }
      it { is_expected.to include(Date.new(2016, 9, 30)) }
      it { is_expected.to include(Date.new(2016, 10, 31)) }
      it { is_expected.to include(Date.new(2016, 11, 30)) }
      it { is_expected.to include(Date.new(2016, 12, 31)) }
      it { is_expected.to include(Date.new(2017, 1, 31)) }
      it { is_expected.to include(Date.new(2017, 2, 28)) }
      it { is_expected.to include(Date.new(2017, 3, 31)) }
      it { is_expected.to include(Date.new(2017, 4, 30)) }
    end
  end

  describe "#get_week_number_of_month" do
    context "with 2016/01/01" do
      subject { described_class.new.send(:get_week_number_of_month, Date.new(2016, 1, 1)) }
      it { is_expected.to eq 1 }
    end

    context "with 2016/01/31" do
      subject { described_class.new.send(:get_week_number_of_month, Date.new(2016, 1, 31)) }
      it { is_expected.to eq 5 }
    end

    context "with 2016/02/29" do
      subject { described_class.new.send(:get_week_number_of_month, Date.new(2016, 2, 29)) }
      it { is_expected.to eq 5 }
    end
  end

  describe "#get_date_by_ordinal_week" do
    context "first sunday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 1, sunday) }
      it { is_expected.to eq Date.new(2016, 1, 3) }
    end

    context "first monday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 1, monday) }
      it { is_expected.to eq Date.new(2016, 1, 4) }
    end

    context "first tuesday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 1, tuesday) }
      it { is_expected.to eq Date.new(2016, 1, 5) }
    end

    context "first wednesday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 1, wednesday) }
      it { is_expected.to eq Date.new(2016, 1, 6) }
    end

    context "first thursday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 1, thursday) }
      it { is_expected.to eq Date.new(2016, 1, 7) }
    end

    context "first friday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 1, friday) }
      it { is_expected.to eq Date.new(2016, 1, 1) }
    end

    context "first saturday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 1, saturday) }
      it { is_expected.to eq Date.new(2016, 1, 2) }
    end

    context "5th friday of January" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 1, 5, friday) }
      it { is_expected.to eq Date.new(2016, 1, 29) }
    end

    context "5th monday of April" do
      subject { described_class.new.send(:get_date_by_ordinal_week, 2016, 4, 5, monday) }
      it { is_expected.to be_nil }
    end
  end

  describe "#get_date_by_nearest_ordinal_week" do
    context "first sunday of January" do
      subject { described_class.new.send(:get_date_by_nearest_ordinal_week, 2016, 1, 1, sunday) }
      it { is_expected.to eq Date.new(2016, 1, 3) }
    end

    context "5th friday of January" do
      subject { described_class.new.send(:get_date_by_nearest_ordinal_week, 2016, 1, 5, friday) }
      it { is_expected.to eq Date.new(2016, 1, 29) }
    end

    context "5th monday of April" do
      subject { described_class.new.send(:get_date_by_nearest_ordinal_week, 2016, 4, 5, monday) }
      it { is_expected.to eq Date.new(2016, 4, 25) }
    end
  end
end
