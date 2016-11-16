require 'spec_helper'

describe Rss::WeatherXml::Trigger::WeatherAlert, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:rss_weather_xml_trigger_weather_alert) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_15_08_130412_02VPWW53.xml))) }
    let(:page) { create(:rss_weather_xml_page, xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: REXML::Document.new(page.xml)) }
    subject { create(:rss_weather_xml_trigger_weather_alert) }

    before do
      region_2920100 = create(:rss_weather_xml_forecast_region_2920100)
      region_2920200 = create(:rss_weather_xml_forecast_region_2920200)
      region_2920300 = create(:rss_weather_xml_forecast_region_2920300)
      region_2920400 = create(:rss_weather_xml_forecast_region_2920400)
      subject.target_region_ids = [ region_2920100.id, region_2920200.id, region_2920300.id, region_2920400.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel('2011-09-04T00:10:00+09:00') do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Rss::WeatherXml::Type::FORECAST
      expect(context.area_codes).to eq %w(2920100 2920200 2920300 2920400)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
        expect(context.type).to eq Rss::WeatherXml::Type::FORECAST
        expect(context.area_codes).to eq %w(2920100 2920200 2920300 2920400)
      end
      expect(flag).to eq 1
    end
  end
end
