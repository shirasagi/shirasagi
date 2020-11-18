require 'spec_helper'

describe Jmaxml::Trigger::LandslideInfo, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_landslide_info) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_17_01_130906_VXWW40-modified.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    let(:area_codes) do
      %w(
        4010000 4013000 4020200 4020300 4020400 4020500 4020600 4020700
        4021000 4021100 4021200 4021300 4021400 4021500 4021600 4021700
        4021800 4021900 4022000 4022100 4022300 4022400 4022500 4022600
        4022700 4022800 4022900 4023000 4030500 4034100 4034200 4034300
        4034400 4034500 4034800 4034900 4038100 4038200 4038300 4038400
        4040100 4040200 4042100 4044700 4044800 4050300 4052200 4054400
        4060100 4060200 4060400 4060500 4060800 4060900 4061000 4062100
        4062500 4064200 4064600 4064700
      )
    end
    subject { create(:jmaxml_trigger_landslide_info) }

    before do
      target_region_ids = []
      area_codes.each do |area_code|
        region = create("jmaxml_forecast_region_#{area_code}".to_sym)
        target_region_ids << region.id
      end
      subject.target_region_ids = target_region_ids
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Jmaxml::Type::LAND_SLIDE
      expect(context.area_codes & area_codes).not_to eq []
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
      end
      expect(flag).to eq 1
      expect(context.type).to eq Jmaxml::Type::LAND_SLIDE
      expect(context.area_codes & area_codes).not_to eq []
    end
  end
end
