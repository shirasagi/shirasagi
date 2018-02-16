require 'spec_helper'

describe Opendata::DatasetDownloadReport, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:opendata_node_dataset) }
  let!(:user) { cms_user }
  let(:today) { Time.zone.local('2018-1-1 10:00') }

  around do |example|
    Timecop.travel(today) { example.run }
  end

  describe "#initialize" do
    subject do
      described_class.new(params)
    end

    context "when not params" do
      let(:params) { {} }
      it do
        expect(subject.start_year).to eq(2018)
        expect(subject.start_month).to eq(1)
        expect(subject.end_year).to eq(2018)
        expect(subject.end_month).to eq(1)
      end
    end
  end

  describe "#years" do
    subject { described_class.new.years }
    it do
      is_expected.to eq [
        ["2018年", 2018],
        ["2017年", 2017],
        ["2016年", 2016],
        ["2015年", 2015],
        ["2014年", 2014],
        ["2013年", 2013],
        ["2012年", 2012],
        ["2011年", 2011],
        ["2010年", 2010],
        ["2009年", 2009],
        ["2008年", 2008]]
    end
  end

  describe "#months" do
    subject { described_class.new.months }
    it do
      is_expected.to eq [
        ["1月", 1],
        ["2月", 2],
        ["3月", 3],
        ["4月", 4],
        ["5月", 5],
        ["6月", 6],
        ["7月", 7],
        ["8月", 8],
        ["9月", 9],
        ["10月", 10],
        ["11月", 11],
        ["12月", 12]]
    end
  end

  describe "#types" do
    subject { described_class.new.types }
    it do
      is_expected.to eq [
        ['日', :day],
        ['月', :month],
        ['年', :year]]
    end
  end

  describe "#start_date" do
    subject { described_class.new(params).start_date }

    context "when none params" do
      let(:params) { {} }
      it { is_expected.to eq today }
    end

    context "when there params" do
      let(:params) do
        {
          start_year: 2016,
          start_month: 2
        }
      end
      it { is_expected.to eq Time.zone.local(2016, 2, 1) }
    end
  end

  describe "#end_date" do
    subject { described_class.new(params).end_date }

    context "when none params" do
      let(:params) { {} }
      it { is_expected.to eq today.end_of_month }
    end

    context "when there params" do
      let(:params) do
        {
          end_year: 2016,
          end_month: 2
        }
      end
      it { is_expected.to eq Time.zone.local(2016, 2, 1).end_of_month }
    end
  end

  describe "#csv" do
    subject do
      instance.csv
    end
    let(:aggregate_class_instance) { instance_double(aggregate_class, csv: nil) }
    let(:instance) { described_class.new(params) }

    before do
      allow(aggregate_class).to receive(:new).with(instance) { aggregate_class_instance }
    end

    context "when type is year" do
      let(:params) { {type: "year"} }
      let(:aggregate_class) { Opendata::DatasetDownloadReport::Aggregate::Year }

      it do
        subject
        expect(aggregate_class).to have_received(:new).once
        expect(aggregate_class_instance).to have_received(:csv).once
      end
    end

    context "when type is month" do
      let(:params) { {type: "month"} }
      let(:aggregate_class) { Opendata::DatasetDownloadReport::Aggregate::Month }

      it do
        subject
        expect(aggregate_class).to have_received(:new).once
        expect(aggregate_class_instance).to have_received(:csv).once
      end
    end

    context "when type is day" do
      let(:params) { {type: "day"} }
      let(:aggregate_class) { Opendata::DatasetDownloadReport::Aggregate::Day }

      it do
        subject
        expect(aggregate_class).to have_received(:new).once
        expect(aggregate_class_instance).to have_received(:csv).once
      end
    end
  end

  describe "#validate" do
    subject do
      described_class.new(params)
    end

    context "start_date is newest than end_date" do
      let(:params) do
        {
          start_year: 2018,
          start_month: 1,
          end_year: 2018,
          end_month: 2
        }
      end
      it { expect(subject).to be_valid }
    end

    context "start_date is older than end_date" do
      let(:params) do
        {
          start_year: 2018,
          start_month: 3,
          end_year: 2018,
          end_month: 2
        }
      end
      it { expect(subject).to have(1).errors_on(:base) }
    end
  end
end
