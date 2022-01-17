require 'spec_helper'

describe Jmaxml::Trigger::TsunamiAlert, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_tsunami_alert) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
    its(:sub_types) { is_expected.to eq %w(special_alert alert warning) }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_10_120615_02tsunamiyohou1.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_tsunami_alert) }

    before do
      region_100 = create(:jmaxml_tsunami_region_c100)
      region_101 = create(:jmaxml_tsunami_region_c101)
      region_102 = create(:jmaxml_tsunami_region_c102)
      region_110 = create(:jmaxml_tsunami_region_c110)
      subject.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    it "returns true" do
      expect(subject.verify(page, context)).to be_truthy
      expect(context.type).to eq Jmaxml::Type::TSUNAMI
      expect(context.area_codes).to eq %w(100 101 102)
    end

    it "calls block" do
      flag = 0
      subject.verify(page, context) do
        flag = 1
        expect(context.type).to eq Jmaxml::Type::TSUNAMI
        expect(context.area_codes).to eq %w(100 101 102)
      end
      expect(flag).to eq 1
    end
  end

  describe 'ss-4354: when category code 72 is occurred' do
    let(:xml_path1) { Rails.root.join(*%w(spec fixtures jmaxml 20220116050009_0_VTSE41_010000.xml.gz)) }
    let(:xml1) { Zlib::GzipReader.open(xml_path1) { |gz| gz.read } }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_tsunami_alert) }

    before do
      region_580 = create(:jmaxml_tsunami_region_c580)
      subject.target_region_ids = [ region_580.id ]
      subject.save!
    end

    it do
      report_datetime = REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip
      Timecop.freeze(report_datetime.in_time_zone + 30.minutes) do
        expect(subject.verify(page, context)).to be_falsey
        expect(context.type).to be_blank
        expect(context.area_codes).to be_blank
      end
    end
  end
end
