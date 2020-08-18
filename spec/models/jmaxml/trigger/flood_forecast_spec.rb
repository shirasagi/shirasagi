require 'spec_helper'

describe Jmaxml::Trigger::FloodForecast, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_flood_forecast) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_16_01_100806_kasenkozui1.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_flood_forecast) }

    before do
      region1 = create(:jmaxml_water_level_station_85050900020300042)
      region2 = create(:jmaxml_water_level_station_85050900020300045)
      region3 = create(:jmaxml_water_level_station_85050900020300053)
      subject.target_region_ids = [ region1.id, region2.id, region3.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Jmaxml::Type::FLOOD
      expect(context.area_codes).to eq %w(85050900020300045)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
      end
      expect(flag).to eq 1
      expect(context.type).to eq Jmaxml::Type::FLOOD
      expect(context.area_codes).to eq %w(85050900020300045)
    end
  end
end
