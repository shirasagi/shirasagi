require 'spec_helper'

describe Rss::WeatherXml::Trigger::TsunamiAlert, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:rss_weather_xml_trigger_tsunami_alert) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-39_10_120615_02tsunamiyohou1.xml))) }
    let(:page) { create(:rss_weather_xml_page, xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: REXML::Document.new(page.xml)) }
    subject { create(:rss_weather_xml_trigger_tsunami_alert) }

    before do
      region_100 = create(:rss_weather_xml_tsunami_region_100)
      region_101 = create(:rss_weather_xml_tsunami_region_101)
      region_102 = create(:rss_weather_xml_tsunami_region_102)
      region_110 = create(:rss_weather_xml_tsunami_region_110)
      subject.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel('2011-03-11T05:50:00Z') do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Rss::WeatherXml::Type::TSUNAMI
      expect(context.area_codes).to eq %w(101 100 102)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
        expect(context.type).to eq Rss::WeatherXml::Type::TSUNAMI
        expect(context.area_codes).to eq %w(101 100 102)
      end
      expect(flag).to eq 1
    end
  end
end
