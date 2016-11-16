require 'spec_helper'

describe Rss::WeatherXml::Trigger::LandslideInfo, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:rss_weather_xml_trigger_landslide_info) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_17_02_130906_VXWW40_03.xml))) }
    let(:page) { create(:rss_weather_xml_page, xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: REXML::Document.new(page.xml)) }
    subject { create(:rss_weather_xml_trigger_landslide_info) }

    before do
      region1 = create(:rss_weather_xml_forecast_region_120200)
      region2 = create(:rss_weather_xml_forecast_region_123600)
      region3 = create(:rss_weather_xml_forecast_region_133100)
      region4 = create(:rss_weather_xml_forecast_region_133200)
      subject.target_region_ids = [ region1.id, region2.id, region3.id, region4.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel('2013-08-23T22:15:00+09:00') do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Rss::WeatherXml::Type::LAND_SLIDE
      expect(context.area_codes).to eq %w(133100 133200)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
      end
      expect(flag).to eq 1
      expect(context.type).to eq Rss::WeatherXml::Type::LAND_SLIDE
      expect(context.area_codes).to eq %w(133100 133200)
    end
  end
end
