require 'spec_helper'

describe Rss::WeatherXml::Trigger::VolcanoFlash, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:rss_weather_xml_trigger_volcano_flash) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_67_01_150514_VFVO56-1.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:rss_weather_xml_trigger_volcano_flash) }

    before do
      region1 = create(:rss_weather_xml_forecast_region_2042900)
      region2 = create(:rss_weather_xml_forecast_region_2043200)
      subject.target_region_ids = [ region1.id, region2.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Rss::WeatherXml::Type::VOLCANO
      expect(context.area_codes).to eq %w(2042900 2043200)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
        expect(context.type).to eq Rss::WeatherXml::Type::VOLCANO
        expect(context.area_codes).to eq %w(2042900 2043200)
      end
      expect(flag).to eq 1
    end
  end
end
