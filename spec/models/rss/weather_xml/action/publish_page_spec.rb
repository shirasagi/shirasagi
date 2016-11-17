require 'spec_helper'

describe Rss::WeatherXml::Action::PublishPage, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:rss_weather_xml_action_publish_page) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:publish_state) { is_expected.to eq 'draft' }
  end

  describe '#execute' do
    let(:xmldoc) { REXML::Document.new(xml1) }
    let(:report_time) { REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
    let(:target_time) { REXML::XPath.first(xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip }
    let(:event_id) { REXML::XPath.first(xmldoc, '/Report/Head/EventID/text()').to_s.strip }
    let(:rss_node) { create(:rss_node_weather_xml) }
    let!(:rss_page1) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, xml: xml1) }
    let!(:article_node) { create(:article_node_page) }
    let(:context) { OpenStruct.new(site: site, node: rss_node, xmldoc: xmldoc) }
    subject { create(:rss_weather_xml_action_publish_page) }

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    context 'when quake intensity flash is given' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-39_11_120615_01shindosokuhou3.xml))) }
      let(:trigger) { create(:rss_weather_xml_trigger_quake_intensity_flash) }

      before do
        region_210 = create(:rss_weather_xml_region_210)
        region_211 = create(:rss_weather_xml_region_211)
        region_212 = create(:rss_weather_xml_region_212)
        region_213 = create(:rss_weather_xml_region_213)
        trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
        trigger.save!

        subject.publish_to_id = article_node.id
        subject.save!
      end

      it do
        trigger.verify(page, context) do
          subject.execute(page, context)
        end

        expect(Article::Page.count).to eq 1
        Article::Page.first.tap do |page|
          expect(page.name).to eq "#{I18n.l(Time.zone.parse(target_time), format: :long)} ころ地震がありました"
          expect(page.state).to eq subject.publish_state
          expect(page.html).to include('<article class="jmaxml quake">')
          expect(page.html).to include('<h2>2011年3月11日 14時46分 ころ地震がありました。</h2>')
          expect(page.html).to include('<li>岩手県沿岸南部：震度 6弱</li>')
          expect(page.html).to include('<li>岩手県内陸南部：震度 6弱</li>')
          expect(page.html).to include('<li>岩手県沿岸北部：震度 5強</li>')
          expect(page.html).to include('<li>岩手県内陸北部：震度 5強</li>')
          expect(page.html).to include('<p>今後の情報に注意してください。</p>')
        end
      end
    end

    context 'when quake info is given' do
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-35_06_100915_03zenkokusaisumo1.xml))) }
      let(:trigger) { create(:rss_weather_xml_trigger_quake_info) }

      before do
        region_210 = create(:rss_weather_xml_region_210)
        region_211 = create(:rss_weather_xml_region_211)
        region_212 = create(:rss_weather_xml_region_212)
        region_213 = create(:rss_weather_xml_region_213)
        trigger.earthquake_intensity = '4'
        trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
        trigger.save!

        subject.publish_to_id = article_node.id
        subject.save!
      end

      it do
        trigger.verify(page, context) do
          subject.execute(page, context)
        end

        expect(Article::Page.count).to eq 1
        Article::Page.first.tap do |page|
          expect(page.name).to eq "#{I18n.l(Time.zone.parse(target_time), format: :long)} ころ地震がありました"
          expect(page.state).to eq subject.publish_state
          expect(page.html).to include('<article class="jmaxml quake">')
          expect(page.html).to include('<h2>2008年6月14日 08時47分 ころ地震がありました。</h2>')
          expect(page.html).to include('<li>岩手県内陸南部：震度 6強</li>')
          expect(page.html).to include('<li>岩手県沿岸北部：震度 4</li>')
          expect(page.html).to include('<li>岩手県沿岸南部：震度 4</li>')
          expect(page.html).to include('<li>岩手県内陸北部：震度 4</li>')
          expect(page.html).to include("<p>この地震による津波の心配はありません。\nこの地震について、緊急地震速報を発表しています。</p>")
        end
      end
    end
  end
end
