require 'spec_helper'

RSpec.describe Gws::Schedule::RepeatPlan, type: :model, dbscope: :example do
  describe '#plan_dates' do
    context 'when daily is given as repeat_type' do
      let(:repeat_start) { Date.new(2016, 5, 1) }
      let(:repeat_end) { Date.new(2017, 5, 1) }
      let(:interval) { 1 }
      let(:item) do
        described_class.new(
          repeat_type: 'daily', repeat_start: repeat_start, repeat_end: repeat_end,
          interval: interval
        )
      end
      subject { item.plan_dates }

      it { is_expected.to include(Date.new(2016, 5, 1)) }
      it { is_expected.to include(Date.new(2017, 4, 30)) }
      it { is_expected.to include(Date.new(2017, 5, 1)) }
      it { is_expected.not_to include(Date.new(2017, 5, 2)) }
      it { expect(subject.count).to eq 366 }
    end

    context 'when weekly is given as repeat_type' do
      let(:repeat_start) { Date.new(2016, 5, 1) }
      let(:interval) { 1 }

      context 'when wdays is not given' do
        let(:repeat_end) { Date.new(2017, 4, 30) }
        let(:item) do
          described_class.new(
            repeat_type: 'weekly', repeat_start: repeat_start, repeat_end: repeat_end,
            interval: interval
          )
        end
        subject { item.plan_dates }

        it { is_expected.to include(Date.new(2016, 5, 1)) }
        it { is_expected.to include(Date.new(2017, 4, 30)) }
        it { is_expected.not_to include(Date.new(2017, 5, 1)) }
        it { expect(subject.count).to eq 53 }
      end

      context 'when wdays is not given' do
        let(:repeat_end) { Date.new(2017, 4, 28) }
        let(:wdays) { %w(2 5) }
        let(:item) do
          described_class.new(
            repeat_type: 'weekly', repeat_start: repeat_start, repeat_end: repeat_end,
            interval: interval, wdays: wdays
          )
        end
        subject { item.plan_dates }

        it { is_expected.not_to include(Date.new(2016, 5, 1)) }
        it { is_expected.to include(Date.new(2016, 5, 3)) }
        it { is_expected.to include(Date.new(2016, 5, 6)) }
        it { is_expected.to include(Date.new(2017, 4, 25)) }
        it { is_expected.to include(Date.new(2017, 4, 28)) }
        it { is_expected.not_to include(Date.new(2017, 5, 1)) }
        it { expect(subject.count).to eq 104 }
      end

      context 'when empty range is given' do
        let(:repeat_end) { repeat_start + 1.day }
        let(:wdays) { %w(2 5) }
        let(:item) do
          described_class.new(
            repeat_type: 'weekly', repeat_start: repeat_start, repeat_end: repeat_end,
            interval: interval, wdays: wdays
          )
        end
        subject { item.plan_dates }
        it { expect(subject.count).to eq 0 }
        it { expect(subject.empty?).to be_truthy }
      end
    end

    context 'when monthly is given as repeat_type' do
      let(:repeat_start) { Date.new(2016, 5, 31) }
      let(:interval) { 1 }

      context 'when data is given as repeat_base' do
        let(:repeat_end) { Date.new(2017, 4, 30) }
        let(:item) do
          described_class.new(
            repeat_type: 'monthly', repeat_start: repeat_start, repeat_end: repeat_end,
            interval: interval, repeat_base: 'date'
          )
        end
        subject { item.plan_dates }

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
        it { expect(subject.count).to eq 12 }
      end

      context 'when wday is given as repeat_base' do
        let(:repeat_end) { Date.new(2017, 4, 25) }
        let(:item) do
          described_class.new(
            repeat_type: 'monthly', repeat_start: repeat_start, repeat_end: repeat_end,
            interval: interval, repeat_base: 'wday'
          )
        end
        subject { item.plan_dates }

        it { is_expected.to include(Date.new(2016, 5, 31)) }
        it { is_expected.to include(Date.new(2016, 6, 28)) }
        it { is_expected.to include(Date.new(2016, 7, 26)) }
        it { is_expected.to include(Date.new(2016, 8, 30)) }
        it { is_expected.to include(Date.new(2016, 9, 27)) }
        it { is_expected.to include(Date.new(2016, 10, 25)) }
        it { is_expected.to include(Date.new(2016, 11, 29)) }
        it { is_expected.to include(Date.new(2016, 12, 27)) }
        it { is_expected.to include(Date.new(2017, 1, 31)) }
        it { is_expected.to include(Date.new(2017, 2, 28)) }
        it { is_expected.to include(Date.new(2017, 3, 28)) }
        it { is_expected.to include(Date.new(2017, 4, 25)) }
        it { expect(subject.count).to eq 12 }
      end
    end

    context 'when yearly is given as repeat_type' do
      let(:repeat_start) { Date.new(2016, 5, 1) }
      let(:repeat_end) { Date.new(2017, 5, 1) }
      let(:interval) { 1 }
      let(:item) do
        described_class.new(
          repeat_type: 'yearly', repeat_start: repeat_start, repeat_end: repeat_end,
          interval: interval
        )
      end
      subject { item.plan_dates }

      it { is_expected.to include(Date.new(2016, 5, 1)) }
      it { is_expected.to include(Date.new(2017, 5, 1)) }
      it { expect(subject.count).to eq 2 }
    end
  end
end
