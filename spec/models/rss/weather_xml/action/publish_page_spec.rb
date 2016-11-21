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
    context 'when alert/info is received' do
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
            expect(page.name).to eq '震度速報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml quake">')
            expect(page.html).to include('<h2>2011年3月11日 14時46分ごろ地震がありました。</h2>')
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
            expect(page.name).to eq '震源・震度に関する情報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml quake">')
            expect(page.html).to include('<h2>2008年6月14日 08時47分ごろ地震がありました。</h2>')
            expect(page.html).to include('<li>岩手県内陸南部：震度 6強</li>')
            expect(page.html).to include('<li>岩手県沿岸北部：震度 4</li>')
            expect(page.html).to include('<li>岩手県沿岸南部：震度 4</li>')
            expect(page.html).to include('<li>岩手県内陸北部：震度 4</li>')
            expect(page.html).to include("<p>この地震による津波の心配はありません。\nこの地震について、緊急地震速報を発表しています。</p>")
          end
        end
      end

      context 'when tsunami alert is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-39_10_120615_02tsunamiyohou1.xml))) }
        let(:trigger) { create(:rss_weather_xml_trigger_tsunami_alert) }

        before do
          region_100 = create(:rss_weather_xml_tsunami_region_100)
          region_101 = create(:rss_weather_xml_tsunami_region_101)
          region_102 = create(:rss_weather_xml_tsunami_region_102)
          region_110 = create(:rss_weather_xml_tsunami_region_110)
          trigger.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id ]
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
            expect(page.name).to eq '津波警報・注意報・予報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml tsunami">')
            expect(page.html).to include('東日本大震災クラスの津波が来襲します。')
            expect(page.html).to include('<tr><td>北海道太平洋沿岸中部</td><td>津波警報</td><td>2011年3月11日 15時30分</td><td></td></tr>')
            expect(page.html).to include('<tr><td>北海道太平洋沿岸東部</td><td>津波注意報</td><td>2011年3月11日 15時30分</td><td></td></tr>')
            expect(page.html).to include('<tr><td>北海道太平洋沿岸西部</td><td>津波注意報</td><td>2011年3月11日 15時40分</td><td></td></tr>')
            expect(page.html).to include('<dt>地震発生時刻</dt><dd>2011年3月11日 14時46分</dd>')
            expect(page.html).to include('<dt>震源地</dt><dd>三陸沖 牡鹿半島の東南東１３０ｋｍ付近</dd>')
            expect(page.html).to include('<dt>座標・深さ</dt><dd>北緯３８．０度　東経１４２．９度　深さ　１０ｋｍ</dd>')
            expect(page.html).to include('<dt>マグニチュード</dt><dd>Ｍ８を超える巨大地震</dd>')
            expect(page.html).to include('大きな津波が襲い甚大な被害が発生します。')
          end
        end
      end

      context 'when tsunami info is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-39_05_100831_11tsunamijohou1.xml))) }
        let(:trigger) { create(:rss_weather_xml_trigger_tsunami_info) }

        before do
          region_100 = create(:rss_weather_xml_tsunami_region_100)
          region_101 = create(:rss_weather_xml_tsunami_region_101)
          region_102 = create(:rss_weather_xml_tsunami_region_102)
          region_110 = create(:rss_weather_xml_tsunami_region_110)
          trigger.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id ]
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
            expect(page.name).to eq '津波情報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml tsunami">')
            expect(page.html).to include('<p>各地の満潮時刻と津波到達予想時刻をお知らせします。</p>')
            expect(page.html).to include('<tr><td>北海道太平洋沿岸東部</td><td>津波の津波警報</td><td>2010年2月28日 13時00分</td><td>2m</td></tr>')
            expect(page.html).to include('<tr><td>北海道太平洋沿岸中部</td><td>津波の津波警報</td><td>2010年2月28日 13時30分</td><td>2m</td></tr>')
            expect(page.html).to include('<tr><td>北海道太平洋沿岸西部</td><td>津波の津波警報</td><td>2010年2月28日 14時00分</td><td>1m</td></tr>')
            expect(page.html).to include('<tr><td>北海道日本海沿岸北部</td><td>津波予報（若干の海面変動）</td><td></td><td>0.2m</td></tr>')
            expect(page.html).to include('<dt>地震発生時刻</dt><dd>2010年2月27日 15時34分</dd>')
            expect(page.html).to include('<dt>震源地</dt><dd>南米西部 </dd>')
            expect(page.html).to include('<dt>座標・深さ</dt><dd>南緯３６．１度　西経　７２．６度　深さ不明</dd>')
            expect(page.html).to include('<dt>マグニチュード</dt><dd>8.6</dd>')
            expect(page.html).to include('<p>津波と満潮が重なると、津波はより高くなりますので一層厳重な警戒が必要です。</p>')
          end
        end
      end

      context 'when weather alert is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_15_08_130412_02VPWW53.xml))) }
        let(:trigger) { create(:rss_weather_xml_trigger_weather_alert) }

        before do
          region_2920100 = create(:rss_weather_xml_forecast_region_2920100)
          region_2920200 = create(:rss_weather_xml_forecast_region_2920200)
          region_2920300 = create(:rss_weather_xml_forecast_region_2920300)
          region_2920400 = create(:rss_weather_xml_forecast_region_2920400)
          trigger.target_region_ids = [ region_2920100.id, region_2920200.id, region_2920300.id, region_2920400.id ]
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
            expect(page.name).to eq '気象特別警報・警報・注意報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml forecast">')
            expect(page.html).to include('<h2>2011年9月4日 00時10分 奈良地方気象台発表</h2>')
            expect(page.html).to include('<p>【特別警報（大雨）】奈良県では、４日昼過ぎまで土砂災害に、４日朝まで低い土地の浸水や河川の増水に警戒して下さい。</p>')
            expect(page.html).to include('<tr><td>奈良市</td><td>大雨特別警報、雷注意報、強風注意報、洪水注意報</td></tr>')
            expect(page.html).to include('<tr><td>大和高田市</td><td>大雨特別警報、洪水警報、雷注意報、強風注意報</td></tr>')
            expect(page.html).to include('<tr><td>大和郡山市</td><td>大雨特別警報、洪水警報、雷注意報、強風注意報</td></tr>')
            expect(page.html).to include('<tr><td>天理市</td><td>大雨特別警報、雷注意報、強風注意報、洪水注意報</td></tr>')
          end
        end

        context 'when flood forecast is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_16_01_100806_kasenkozui1.xml))) }
          let(:trigger) { create(:rss_weather_xml_trigger_flood_forecast) }
          let(:main_sentence) do
            %w(
              揖斐川中流の万石水位観測所では、はん濫注意水位・流量（レベル２）に到達しました。
              水位・流量はさらに上昇する見込みです。今後の洪水予報に注意して下さい。).join
          end

          before do
            region1 = create(:rss_weather_xml_water_level_station_85050900020300042)
            region2 = create(:rss_weather_xml_water_level_station_85050900020300045)
            region3 = create(:rss_weather_xml_water_level_station_85050900020300053)
            trigger.target_region_ids = [ region1.id, region2.id, region3.id ]
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
              expect(page.name).to eq '指定河川洪水予報'
              expect(page.state).to eq subject.publish_state
              puts page.html
              expect(page.html).to include('<div class="jmaxml flood">')
              expect(page.html).to include('<h2>2008年9月3日 04時15分 木曽川上流河川事務所 岐阜地方気象台発表</h2>')
              expect(page.html).to include('<p>揖斐川中流では　はん濫注意水位・流量に到達　水位はさらに上昇</p>')
              expect(page.html).to include('<dt>河川</dt><dd>揖斐川</dd>')
              expect(page.html).to include('<dt>発表種別</dt><dd>はん濫注意情報</dd>')
              expect(page.html).to include('<dt>洪水予報種別</dt><dd>洪水注意報（発表）</dd>')
              expect(page.html).to include("<dt>内容</dt><dd>#{main_sentence}</dd>")
              expect(page.html).to include('<dt>水位観測所</dt><dd>万石水位観測所（岐阜県大垣市万石）</dd>')
              expect(page.html).to include('<p>所により１時間に５０ミリの雨が降っています。この雨は今後次第に弱まるでしょう。</p>')
            end
          end
        end

        context 'when landslide info is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_17_02_130906_VXWW40_03.xml))) }
          let(:trigger) { create(:rss_weather_xml_trigger_landslide_info) }
          let(:headline_text) do
            "《全警戒解除》\n大雨が弱まり、多発的な土砂災害が発生するおそれは少なくなりました。"
          end

          before do
            region1 = create(:rss_weather_xml_forecast_region_120200)
            region2 = create(:rss_weather_xml_forecast_region_123600)
            region3 = create(:rss_weather_xml_forecast_region_133100)
            region4 = create(:rss_weather_xml_forecast_region_133200)
            trigger.target_region_ids = [ region1.id, region2.id, region3.id, region4.id ]
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
              expect(page.name).to eq '土砂災害警戒情報'
              expect(page.state).to eq subject.publish_state
              puts page.html
              expect(page.html).to include('<div class="jmaxml landslide">')
              expect(page.html).to include('<h2>2013年8月23日 22時15分 北海道渡島総合振興局 函館地方気象台発表</h2>')
              expect(page.html).to include("<p>#{headline_text}</p>")
              expect(page.html).to include('<tr><td>解除</td><td>松前町、福島町</td></tr>')
            end
          end
        end

        context 'when volcano flash is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_67_01_150514_VFVO56-1.xml))) }
          let(:trigger) { create(:rss_weather_xml_trigger_volcano_flash) }

          before do
            region1 = create(:rss_weather_xml_forecast_region_2042900)
            region2 = create(:rss_weather_xml_forecast_region_2043200)
            trigger.target_region_ids = [ region1.id, region2.id ]
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
              expect(page.name).to eq '噴火速報'
              expect(page.state).to eq subject.publish_state
              puts page.html
              expect(page.html).to include('<div class="jmaxml volcano">')
              expect(page.html).to include('<h2>2014年9月27日 11時53分 気象庁地震火山部発表</h2>')
              expect(page.html).to include('<p>＜御嶽山で噴火が発生＞</p>')
              expect(page.html).to include('<p>御嶽山で、平成２６年９月２７日１１時５３分頃、噴火が発生しました。</p>')
              expect(page.html).to include('<li>長野県王滝村</li>')
              expect(page.html).to include('<li>長野県木曽町</li>')
            end
          end
        end

        context 'when ash fall forecast is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_66_01_141024_VFVO53.xml))) }
          let(:trigger) { create(:rss_weather_xml_trigger_ash_fall_forecast) }

          before do
            region_4620100 = create(:rss_weather_xml_forecast_region_4620100)
            region_4620300 = create(:rss_weather_xml_forecast_region_4620300)
            region_4621400 = create(:rss_weather_xml_forecast_region_4621400)
            region_4621700 = create(:rss_weather_xml_forecast_region_4621700)
            trigger.target_region_ids = [ region_4620100.id, region_4620300.id, region_4621400.id, region_4621700.id ]
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
              expect(page.name).to eq '火山名　桜島　降灰予報（定時）'
              expect(page.state).to eq subject.publish_state
              puts page.html
              expect(page.html).to include('<div class="jmaxml ashfall">')
              expect(page.html).to include('<h2>2014年6月6日 06時00分 気象庁地震火山部発表</h2>')
              expect(page.html).to include('<p>　現在、桜島は噴火警戒レベル３（入山規制）です。')
              expect(page.html).to include('<tr><td>降灰</td><td>鹿児島県鹿児島市、鹿児島県鹿屋市、鹿児島県垂水市、鹿児島県曽於市</td></tr>')
              expect(page.html).to include('<tr><td>小さな噴石の落下</td><td>鹿児島県鹿児島市</td></tr>')
              expect(page.html).to include('<p>　６日０６時から６日２４時までに噴火が発生した場合には、')
              expect(page.html).to include('<p>　噴煙が高さ３０００ｍまで上がった場合の火山灰')
            end
          end
        end

        context 'when tornado alert is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_19_01_091210_tatsumakijyohou1.xml))) }
          let(:trigger) { create(:rss_weather_xml_trigger_tornado_alert) }

          before do
            region_1310100 = create(:rss_weather_xml_forecast_region_1310100)
            region_1310200 = create(:rss_weather_xml_forecast_region_1310200)
            region_1310300 = create(:rss_weather_xml_forecast_region_1310300)
            region_1310400 = create(:rss_weather_xml_forecast_region_1310400)
            trigger.target_region_ids = [ region_1310100.id, region_1310200.id, region_1310300.id, region_1310400.id ]
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
              expect(page.name).to eq '竜巻注意情報'
              expect(page.state).to eq subject.publish_state
              puts page.html
              expect(page.html).to include('<div class="jmaxml tornado">')
              expect(page.html).to include('<h2>2009年8月10日 07時38分 気象庁予報部発表</h2>')
              expect(page.html).to include('<p>東京地方では、竜巻発生のおそれがあります。')
              expect(page.html).to include('<li>千代田区</li>')
              expect(page.html).to include('<li>中央区</li>')
              expect(page.html).to include('<li>港区</li>')
              expect(page.html).to include('<li>新宿区</li>')
            end
          end
        end
      end
    end

    context 'when alert/info is canceled' do
      let(:xmldoc) { REXML::Document.new(xml2) }
      let(:report_time) { REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
      let(:target_time) { REXML::XPath.first(xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip }
      let(:event_id) { REXML::XPath.first(xmldoc, '/Report/Head/EventID/text()').to_s.strip }
      let(:rss_node) { create(:rss_node_weather_xml) }
      let!(:rss_page1) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, xml: xml1) }
      let!(:rss_page2) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, xml: xml2) }
      let!(:article_node) { create(:article_node_page) }
      let(:context) { OpenStruct.new(site: site, node: rss_node, xmldoc: xmldoc) }
      subject { create(:rss_weather_xml_action_publish_page) }

      around do |example|
        Timecop.travel(report_time) do
          example.run
        end
      end

      context 'when quake intensity flash is canceled' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-39_11_120615_01shindosokuhou3.xml))) }
        let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-39_11_120615_99shindosokuhou3.xml))) }
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
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '【取消】震度速報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml cancel">緊急地震速報（警報）を取り消します。</div>')
          end
        end
      end

      context 'when quake info is canceled' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-35_06_100915_03zenkokusaisumo1.xml))) }
        let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-35_06_100915_06zenkokusaisumo1.xml))) }
        let(:trigger) { create(:rss_weather_xml_trigger_quake_info) }

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
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '【取消】震源・震度に関する情報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml cancel">震源・震度情報を取り消します。</div>')
          end
        end
      end

      context 'when volcano flash is canceled' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_67_01_150514_VFVO56-1.xml))) }
        let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures rss 70_67_01_150514_VFVO56-4.xml))) }
        let(:trigger) { create(:rss_weather_xml_trigger_volcano_flash) }

        before do
          region1 = create(:rss_weather_xml_forecast_region_2042900)
          region2 = create(:rss_weather_xml_forecast_region_2043200)
          trigger.target_region_ids = [ region1.id, region2.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.save!
        end

        it do
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '【取消】噴火速報'
            expect(page.state).to eq subject.publish_state
            puts page.html
            expect(page.html).to include('<div class="jmaxml cancel">噴火速報を取り消します。</div>')
          end
        end
      end
    end
  end
end
