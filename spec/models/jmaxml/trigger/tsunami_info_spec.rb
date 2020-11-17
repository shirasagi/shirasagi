require 'spec_helper'

describe Jmaxml::Trigger::TsunamiInfo, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_tsunami_info) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
    its(:sub_types) { is_expected.to eq %w(special_alert alert warning) }
  end

  describe '#verify' do
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_05_100831_11tsunamijohou1.xml))) }
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_tsunami_info) }

    before do
      region_100 = create(:jmaxml_tsunami_region_100)
      region_101 = create(:jmaxml_tsunami_region_101)
      region_102 = create(:jmaxml_tsunami_region_102)
      region_110 = create(:jmaxml_tsunami_region_110)
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
end
