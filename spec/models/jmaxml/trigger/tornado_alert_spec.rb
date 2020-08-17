require 'spec_helper'

describe Jmaxml::Trigger::TornadoAlert, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_tornado_alert) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_19_01_091210_tatsumakijyohou1.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_tornado_alert) }

    before do
      region_1310100 = create(:jmaxml_forecast_region_1310100)
      region_1310200 = create(:jmaxml_forecast_region_1310200)
      region_1310300 = create(:jmaxml_forecast_region_1310300)
      region_1310400 = create(:jmaxml_forecast_region_1310400)
      subject.target_region_ids = [ region_1310100.id, region_1310200.id, region_1310300.id, region_1310400.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Jmaxml::Type::TORNADO
      expect(context.area_codes).to eq %w(1310100 1310200 1310300 1310400)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
        expect(context.type).to eq Jmaxml::Type::TORNADO
        expect(context.area_codes).to eq %w(1310100 1310200 1310300 1310400)
      end
      expect(flag).to eq 1
    end
  end
end
