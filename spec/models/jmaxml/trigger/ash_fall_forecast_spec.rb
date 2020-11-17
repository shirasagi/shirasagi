require 'spec_helper'

describe Jmaxml::Trigger::AshFallForecast, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_ash_fall_forecast) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
    its(:sub_types) { is_expected.to eq %w(flash regular detail) }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_66_01_141024_VFVO53.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_ash_fall_forecast) }

    before do
      region_4620100 = create(:jmaxml_forecast_region_4620100)
      region_4620300 = create(:jmaxml_forecast_region_4620300)
      region_4621400 = create(:jmaxml_forecast_region_4621400)
      region_4621700 = create(:jmaxml_forecast_region_4621700)
      subject.target_region_ids = [ region_4620100.id, region_4620300.id, region_4621400.id, region_4621700.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Jmaxml::Type::ASH_FALL
      expect(context.area_codes).to eq %w(4620100 4620300 4621400 4621700)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
        expect(context.type).to eq Jmaxml::Type::ASH_FALL
        expect(context.area_codes).to eq %w(4620100 4620300 4621400 4621700)
      end
      expect(flag).to eq 1
    end
  end
end
