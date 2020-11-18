require 'spec_helper'

describe Jmaxml::Trigger::WeatherAlert, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_weather_alert) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
    its(:sub_types) { is_expected.to eq %w(special_alert alert warning) }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_15_08_130412_02VPWW53.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_weather_alert) }

    before do
      region_2920100 = create(:jmaxml_forecast_region_2920100)
      region_2920200 = create(:jmaxml_forecast_region_2920200)
      region_2920300 = create(:jmaxml_forecast_region_2920300)
      region_2920400 = create(:jmaxml_forecast_region_2920400)
      subject.target_region_ids = [ region_2920100.id, region_2920200.id, region_2920300.id, region_2920400.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Jmaxml::Type::FORECAST
      expect(context.area_codes).to eq %w(2920100 2920200 2920300 2920400)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
        expect(context.type).to eq Jmaxml::Type::FORECAST
        expect(context.area_codes).to eq %w(2920100 2920200 2920300 2920400)
      end
      expect(flag).to eq 1
    end

    context 'when disable all sub types' do
      before do
        subject.sub_types = []
        subject.save!
      end

      it "returns false" do
        expect(subject.verify(page, context)).to be_falsey
      end
    end
  end
end
