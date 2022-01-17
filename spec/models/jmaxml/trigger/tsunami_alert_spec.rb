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
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:page) { create(:rss_weather_xml_page, in_xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: xmldoc) }
    subject { create(:jmaxml_trigger_tsunami_alert) }

    describe 'when category code 62 is occurred' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_10_120615_02tsunamiyohou1.xml))) }

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

      context "without block" do
        it do
          expect(subject.verify(page, context)).to be_truthy
          expect(context.type).to eq Jmaxml::Type::TSUNAMI
          expect(context.area_codes).to eq %w(100 101 102)
        end
      end

      context "with block" do
        it do
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

    describe 'when category code 51 is occurred' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_10_120615_02tsunamiyohou1.xml))) }

      before do
        region_300 = create(:jmaxml_tsunami_region_c300)
        subject.target_region_ids = [ region_300.id ]
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_truthy
          expect(context.type).to eq Jmaxml::Type::TSUNAMI
          expect(context.area_codes).to eq %w(300)
        end
      end
    end

    describe 'when category code 52 is occurred' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_10_120615_02tsunamiyohou1.xml))) }

      before do
        region_210 = create(:jmaxml_tsunami_region_c210)
        subject.target_region_ids = [ region_210.id ]
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_truthy
          expect(context.type).to eq Jmaxml::Type::TSUNAMI
          expect(context.area_codes).to eq %w(210)
        end
      end
    end

    describe 'when category code 71 is occurred' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_10_120615_02tsunamiyohou1.xml))) }

      before do
        region_560 = create(:jmaxml_tsunami_region_c560)
        subject.target_region_ids = [ region_560.id ]
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_falsey
          expect(context.type).to be_blank
          expect(context.area_codes).to be_blank
        end
      end
    end

    describe 'when category code 50 is occurred' do
      let(:xml_path1) { Rails.root.join(*%w(spec fixtures jmaxml 32-39_12_13_191025_VTSE41.xml.gz)) }
      let(:xml1) { Zlib::GzipReader.open(xml_path1) { |gz| gz.read } }

      before do
        region_100 = create(:jmaxml_tsunami_region_c100)
        region_101 = create(:jmaxml_tsunami_region_c101)
        region_102 = create(:jmaxml_tsunami_region_c102)
        subject.target_region_ids = [ region_100.id, region_101.id, region_102.id ]
        subject.training_status = 'enabled'
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_falsey
          expect(context.type).to be_blank
          expect(context.area_codes).to be_blank
        end
      end
    end

    describe 'when category code 60 is occurred' do
      let(:xml_path1) { Rails.root.join(*%w(spec fixtures jmaxml 32-39_12_13_191025_VTSE41.xml.gz)) }
      let(:xml1) { Zlib::GzipReader.open(xml_path1) { |gz| gz.read } }

      before do
        region_110 = create(:jmaxml_tsunami_region_c110)
        region_111 = create(:jmaxml_tsunami_region_c111)
        subject.target_region_ids = [ region_110.id, region_111.id ]
        subject.training_status = 'enabled'
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_falsey
          expect(context.type).to be_blank
          expect(context.area_codes).to be_blank
        end
      end
    end

    describe 'when category code 73 is occurred' do
      let(:xml_path1) { Rails.root.join(*%w(spec fixtures jmaxml 32-39_12_13_191025_VTSE41.xml.gz)) }
      let(:xml1) { Zlib::GzipReader.open(xml_path1) { |gz| gz.read } }

      before do
        region_300 = create(:jmaxml_tsunami_region_c300)
        subject.target_region_ids = [ region_300.id ]
        subject.training_status = 'enabled'
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_falsey
          expect(context.type).to be_blank
          expect(context.area_codes).to be_blank
        end
      end
    end

    describe 'when category code 53 is occurred' do
      let(:xml_path1) { Rails.root.join(*%w(spec fixtures jmaxml 32-39_11_02_120615_VTSE41.xml.gz)) }
      let(:xml1) { Zlib::GzipReader.open(xml_path1) { |gz| gz.read } }

      before do
        region_210 = create(:jmaxml_tsunami_region_c210)
        subject.target_region_ids = [ region_210.id ]
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_truthy
          expect(context.type).to eq Jmaxml::Type::TSUNAMI
          expect(context.area_codes).to eq %w(210)
        end
      end
    end

    describe 'ss-4354: when category code 72 is occurred' do
      let(:xml_path1) { Rails.root.join(*%w(spec fixtures jmaxml 20220116050009_0_VTSE41_010000.xml.gz)) }
      let(:xml1) { Zlib::GzipReader.open(xml_path1) { |gz| gz.read } }

      before do
        region_580 = create(:jmaxml_tsunami_region_c580)
        subject.target_region_ids = [ region_580.id ]
        subject.save!
      end

      it do
        Timecop.freeze(report_time.in_time_zone + 30.minutes) do
          expect(subject.verify(page, context)).to be_falsey
          expect(context.type).to be_blank
          expect(context.area_codes).to be_blank
        end
      end
    end
  end
end
