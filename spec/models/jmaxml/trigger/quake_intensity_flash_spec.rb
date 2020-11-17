require 'spec_helper'

describe Jmaxml::Trigger::QuakeIntensityFlash, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_trigger_quake_intensity_flash) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:training_status) { is_expected.to eq 'disabled' }
    its(:test_status) { is_expected.to eq 'disabled' }
    its(:earthquake_intensity) { is_expected.to eq '5+' }
  end

  describe '#verify' do
    context 'when info_type=発表 is given' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_01shindosokuhou3.xml))) }
      let(:xmldoc) { REXML::Document.new(xml1) }
      let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
      let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
      let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
      subject { create(:jmaxml_trigger_quake_intensity_flash) }

      before do
        region_210 = create(:jmaxml_region_210)
        region_211 = create(:jmaxml_region_211)
        region_212 = create(:jmaxml_region_212)
        region_213 = create(:jmaxml_region_213)
        subject.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
        subject.save!
      end

      around do |example|
        Timecop.travel(report_time) do
          example.run
        end
      end

      it "returns true" do
        expect(subject.verify(page, context)).to be_truthy
        expect(context.type).to eq Jmaxml::Type::EARTH_QUAKE
        expect(context.region_eq_infos).to include(include({ pref_name: '岩手県' }))
        expect(context.max_int).to eq '6-'
      end

      it "calls block" do
        flag = 0
        subject.verify(page, context) do
          flag = 1
          expect(context.type).to eq Jmaxml::Type::EARTH_QUAKE
          expect(context.region_eq_infos).to include(include({ pref_name: '岩手県' }))
          expect(context.max_int).to eq '6-'
        end
        expect(flag).to eq 1
      end
    end

    context 'when info_type=取消 is given' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_01shindosokuhou3.xml))) }
      let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_99shindosokuhou3.xml))) }
      let(:xmldoc) { REXML::Document.new(xml2) }
      let(:report_time) { REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
      let(:event_id) { REXML::XPath.first(xmldoc, '/Report/Head/EventID/text()').to_s.strip }
      let(:node) { create(:rss_node_weather_xml) }
      let!(:page1) { create(:rss_weather_xml_page, cur_node: node, event_id: event_id, in_xml: xml1) }
      let!(:page2) { create(:rss_weather_xml_page, cur_node: node, event_id: event_id, in_xml: xml2) }
      let(:context) { OpenStruct.new(site: site, node: node, xmldoc: xmldoc) }
      subject { create(:jmaxml_trigger_quake_intensity_flash) }

      before do
        region_210 = create(:jmaxml_region_210)
        region_211 = create(:jmaxml_region_211)
        region_212 = create(:jmaxml_region_212)
        region_213 = create(:jmaxml_region_213)
        subject.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
        subject.save!
      end

      around do |example|
        Timecop.travel(report_time) do
          example.run
        end
      end

      it "returns true" do
        expect(subject.verify(page2, context)).to be_truthy
        expect(context.type).to eq Jmaxml::Type::EARTH_QUAKE
        expect(context.region_eq_infos).to include(include({ pref_name: '岩手県' }))
        expect(context.max_int).to eq '6-'
        expect(context.last_page).to eq page1
        expect(context.last_xmldoc).not_to be_nil
      end

      it "calls block" do
        flag = 0
        subject.verify(page2, context) do
          flag = 1
          expect(context.type).to eq Jmaxml::Type::EARTH_QUAKE
          expect(context.region_eq_infos).to include(include({ pref_name: '岩手県' }))
          expect(context.max_int).to eq '6-'
          expect(context.last_page).to eq page1
          expect(context.last_xmldoc).not_to be_nil
        end
        expect(flag).to eq 1
      end
    end
  end
end
