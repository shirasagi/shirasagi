require 'spec_helper'

describe Rss::WeatherXml::Trigger::QuakeInfo, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:rss_weather_xml_trigger_quake_info) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
    its(:earthquake_intensity) { is_expected.to eq '5+' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-35_06_100915_03zenkokusaisumo1.xml))) }
    let(:page) { create(:rss_weather_xml_page, xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: REXML::Document.new(page.xml)) }
    subject { create(:rss_weather_xml_trigger_quake_info) }

    before do
      region_210 = create(:rss_weather_xml_region_210)
      region_211 = create(:rss_weather_xml_region_211)
      region_212 = create(:rss_weather_xml_region_212)
      region_213 = create(:rss_weather_xml_region_213)
      subject.earthquake_intensity = '4'
      subject.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel('2008-06-14T08:47:00+09:00') do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
      end
      expect(flag).to eq 1
    end
  end
end
