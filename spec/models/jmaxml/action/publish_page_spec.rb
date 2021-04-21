require 'spec_helper'

describe Jmaxml::Action::PublishPage, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_action_publish_page) }
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
      let!(:rss_page1) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, in_xml: xml1) }
      let!(:article_node) { create(:article_node_page) }
      let!(:category_node) { create(:category_node_page, cur_node: article_node) }
      let(:context) { OpenStruct.new(site: site, node: rss_node, xmldoc: xmldoc) }
      subject { create(:jmaxml_action_publish_page) }

      around do |example|
        Timecop.travel(report_time) do
          example.run
        end
      end

      context 'when quake intensity flash is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_01shindosokuhou3.xml))) }
        let(:trigger) { create(:jmaxml_trigger_quake_intensity_flash) }

        before do
          region_210 = create(:jmaxml_region_210)
          region_211 = create(:jmaxml_region_211)
          region_212 = create(:jmaxml_region_212)
          region_213 = create(:jmaxml_region_213)
          trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
          subject.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '震度速報'
            expect(page.state).to eq subject.publish_state
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml quake">')
            expect(page.html).to include('<time datetime="2011-03-11T14:48:10+09:00">2011年3月11日 14時48分</time>')
            expect(page.html).to include('<span class="publishing-office">気象庁発表</span>')
            expect(page.html).to include('2011年3月11日 14時46分ごろ地震がありました。')
            expect(page.html).to include('<dt>岩手県沿岸南部</dt><dd>震度６弱</dd>')
            expect(page.html).to include('<dt>岩手県内陸南部</dt><dd>震度６弱</dd>')
            expect(page.html).to include('<dt>岩手県沿岸北部</dt><dd>震度５強</dd>')
            expect(page.html).to include('<dt>岩手県内陸北部</dt><dd>震度５強</dd>')
            expect(page.html).to include('<p>今後の情報に注意してください。</p>')
          end
        end
      end

      context 'when quake info is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-35_06_100915_03zenkokusaisumo1.xml))) }
        let(:trigger) { create(:jmaxml_trigger_quake_info) }

        before do
          region_210 = create(:jmaxml_region_210)
          region_211 = create(:jmaxml_region_211)
          region_212 = create(:jmaxml_region_212)
          region_213 = create(:jmaxml_region_213)
          trigger.earthquake_intensity = '4'
          trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
          subject.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '震源・震度情報'
            expect(page.state).to eq subject.publish_state
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml quake">')
            expect(page.html).to include('<time datetime="2008-06-14T08:47:47+09:00">2008年6月14日 08時47分</time>')
            expect(page.html).to include('<span class="publishing-office">気象庁発表</span>')
            expect(page.html).to include('2008年6月14日 08時43分ごろ地震がありました。')
            expect(page.html).to include('<dt>岩手県内陸南部</dt><dd>震度６強</dd>')
            expect(page.html).to include('<dt>岩手県沿岸北部</dt><dd>震度４</dd>')
            expect(page.html).to include('<dt>岩手県沿岸南部</dt><dd>震度４</dd>')
            expect(page.html).to include('<dt>岩手県内陸北部</dt><dd>震度４</dd>')
            expect(page.html).to include('<p>この地震による津波の心配はありません。<br />この地震について、緊急地震速報を発表しています。</p>')
            expect(page.html).to include('<dt>地震発生時刻</dt><dd>2008年6月14日 08時43分ごろ</dd>')
            expect(page.html).to include('<dt>震源地</dt><dd>岩手県内陸南部 </dd>')
            expect(page.html).to include('<dt>座標・深さ</dt><dd>北緯３９．０度　東経１４０．９度　深さ　１０ｋｍ</dd>')
            expect(page.html).to include('<dt>マグニチュード</dt><dd>7.0</dd>')
          end
        end
      end

      context 'when tsunami alert is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_10_120615_02tsunamiyohou1.xml))) }
        let(:trigger) { create(:jmaxml_trigger_tsunami_alert) }

        before do
          region_100 = create(:jmaxml_tsunami_region_100)
          region_101 = create(:jmaxml_tsunami_region_101)
          region_102 = create(:jmaxml_tsunami_region_102)
          region_110 = create(:jmaxml_tsunami_region_110)
          trigger.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
          subject.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '大津波警報・津波警報・津波注意報・津波予報'
            expect(page.state).to eq subject.publish_state
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml tsunami">')
            expect(page.html).to include('<time datetime="2011-03-11T14:49:59+09:00">2011年3月11日 14時49分</time>')
            expect(page.html).to include('<span class="publishing-office">気象庁発表</span>')
            expect(page.html).to include('<p>東日本大震災クラスの津波が来襲します。<br />大津波警報・津波警報を発表しました。<br />')
            expect(page.html).to include('<h2 class="alert">津波警報</h2>')
            expect(page.html).to include('<td>北海道太平洋沿岸中部</td>')
            expect(page.html).to include('<td>2011年3月11日 15時30分</td>')
            expect(page.html).to include('<h2 class="warning">津波注意報</h2>')
            expect(page.html).to include('<td>北海道太平洋沿岸東部</td>')
            expect(page.html).to include('<td>2011年3月11日 15時30分</td>')
            expect(page.html).to include('<td>北海道太平洋沿岸西部</td>')
            expect(page.html).to include('<td>2011年3月11日 15時40分</td>')
            expect(page.html).to include('<strong>大津波警報</strong><br />')
            expect(page.html).to include('大きな津波が襲い甚大な被害が発生します。')
            expect(page.html).to include('<dt>地震発生時刻</dt><dd>2011年3月11日 14時46分ごろ</dd>')
            expect(page.html).to include('<dt>震源地</dt><dd>三陸沖 牡鹿半島の東南東１３０ｋｍ付近</dd>')
            expect(page.html).to include('<dt>座標・深さ</dt><dd>北緯３８．０度　東経１４２．９度　深さ　１０ｋｍ</dd>')
            expect(page.html).to include('<dt>マグニチュード</dt><dd>Ｍ８を超える巨大地震</dd>')
          end
        end
      end

      context 'when tsunami info is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_05_100831_11tsunamijohou1.xml))) }
        let(:trigger) { create(:jmaxml_trigger_tsunami_info) }

        before do
          region_100 = create(:jmaxml_tsunami_region_100)
          region_101 = create(:jmaxml_tsunami_region_101)
          region_102 = create(:jmaxml_tsunami_region_102)
          region_110 = create(:jmaxml_tsunami_region_110)
          trigger.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
          subject.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '各地の満潮時刻・津波到達予想時刻に関する情報'
            expect(page.state).to eq subject.publish_state
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml tsunami">')
            expect(page.html).to include('<time datetime="2010-02-28T09:37:14+09:00">2010年2月28日 09時37分</time>')
            expect(page.html).to include('<span class="publishing-office">気象庁発表</span>')
            expect(page.html).to include('<p>各地の満潮時刻と津波到達予想時刻をお知らせします。</p>')
            expect(page.html).to include('<td>北海道太平洋沿岸東部</td>')
            expect(page.html).to include('<td>2010年2月28日 13時00分</td>')
            expect(page.html).to include('<td>２ｍ</td>')
            expect(page.html).to include('<td>北海道太平洋沿岸中部</td>')
            expect(page.html).to include('<td>2010年2月28日 13時30分</td>')
            expect(page.html).to include('<td>２ｍ</td>')
            expect(page.html).to include('<td>北海道太平洋沿岸西部</td>')
            expect(page.html).to include('<td>2010年2月28日 14時00分</td>')
            expect(page.html).to include('<td>１ｍ</td>')
            expect(page.html).to include('<p>津波と満潮が重なると、津波はより高くなりますので一層厳重な警戒が必要です。</p>')
            expect(page.html).to include('<dt>地震発生時刻</dt><dd>2010年2月27日 15時34分ごろ</dd>')
            expect(page.html).to include('<dt>震源地</dt><dd>南米西部 </dd>')
            expect(page.html).to include('<dt>座標・深さ</dt><dd>南緯３６．１度　西経　７２．６度　深さ不明</dd>')
            expect(page.html).to include('<dt>マグニチュード</dt><dd>8.6</dd>')
          end
        end
      end

      context 'when weather alert is given' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_15_08_130412_02VPWW53.xml))) }
        let(:trigger) { create(:jmaxml_trigger_weather_alert) }

        before do
          region_2920100 = create(:jmaxml_forecast_region_2920100)
          region_2920200 = create(:jmaxml_forecast_region_2920200)
          region_2920300 = create(:jmaxml_forecast_region_2920300)
          region_2920400 = create(:jmaxml_forecast_region_2920400)
          trigger.target_region_ids = [ region_2920100.id, region_2920200.id, region_2920300.id, region_2920400.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
          subject.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '奈良県気象警報・注意報'
            expect(page.state).to eq subject.publish_state
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml forecast">')
            expect(page.html).to include('<time datetime="2011-09-04T00:10:39+09:00">2011年9月4日 00時10分</time>')
            expect(page.html).to include('<span class="publishing-office">奈良地方気象台発表</span>')
            expect(page.html).to include('<p>【特別警報（大雨）】奈良県では、４日昼過ぎまで土砂災害に、４日朝まで低い土地の浸水や河川の増水に警戒して下さい。</p>')
            expect(page.html).to include('<dt class="area">奈良市</dt>')
            expect(page.html).to include('<dt class="area">奈良市</dt>')
            expect(page.html).to include('<dt class="area">大和高田市</dt>')
            expect(page.html).to include('<dt class="area">大和郡山市</dt>')
            expect(page.html).to include('<span class="special-alert">大雨特別警報</span>')
            expect(page.html).to include('<span class="warning">雷注意報</span>')
            expect(page.html).to include('<span class="warning">強風注意報</span>')
            expect(page.html).to include('<span class="warning">洪水注意報</span>')
          end
        end

        context 'when flood forecast is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_16_01_100806_kasenkozui1.xml))) }
          let(:trigger) { create(:jmaxml_trigger_flood_forecast) }
          let(:main_sentence) do
            %w(
              揖斐川中流の万石水位観測所では、はん濫注意水位・流量（レベル２）に到達しました。
              水位・流量はさらに上昇する見込みです。今後の洪水予報に注意して下さい。).join
          end

          before do
            region1 = create(:jmaxml_water_level_station_85050900020300042)
            region2 = create(:jmaxml_water_level_station_85050900020300045)
            region3 = create(:jmaxml_water_level_station_85050900020300053)
            trigger.target_region_ids = [ region1.id, region2.id, region3.id ]
            trigger.save!

            subject.publish_to_id = article_node.id
            subject.category_ids = [ category_node.id ]
            subject.save!
          end

          it do
            trigger.verify(rss_page1, context) do
              subject.execute(rss_page1, context)
            end

            expect(Article::Page.count).to eq 1
            Article::Page.first.tap do |page|
              expect(page.name).to eq '揖斐川中流はん濫注意情報'
              expect(page.state).to eq subject.publish_state
              expect(page.category_ids).to eq [ category_node.id ]
              expect(page.html).to include('<div class="jmaxml flood">')
              expect(page.html).to include('<time datetime="2008-09-03T04:15:00+09:00">2008年9月3日 04時15分</time>')
              expect(page.html).to include('<span class="publishing-office">木曽川上流河川事務所・岐阜地方気象台　共同発表</span>')
              expect(page.html).to include("<p>#{main_sentence}</p>")
              expect(page.html).to include('<dt>岐阜県△△市</dt>')
              expect(page.html).to include('<dd>△△地区 △△地区 △△地区</dd>')
              expect(page.html).to include('<p>所により１時間に５０ミリの雨が降っています。この雨は今後次第に弱まるでしょう。</p>')
            end
          end
        end

        context 'when landslide info is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_17_01_130906_VXWW40-modified.xml))) }
          let(:trigger) { create(:jmaxml_trigger_landslide_info) }
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
          let(:headline_text) do
            [
              '<strong>概況</strong>',
              '　降り続く大雨のため、警戒対象地域では土砂災害の危険度が高まっています。',
              '',
              '<strong>とるべき措置</strong>',
              '　崖の近くなど土砂災害の発生しやすい地区にお住まいの方は、'
            ].join('<br />')
          end

          before do
            target_region_ids = []
            area_codes.each do |area_code|
              region = create("jmaxml_forecast_region_#{area_code}".to_sym)
              target_region_ids << region.id
            end
            trigger.target_region_ids = target_region_ids
            trigger.save!

            subject.publish_to_id = article_node.id
            subject.category_ids = [ category_node.id ]
            subject.save!
          end

          it do
            trigger.verify(rss_page1, context) do
              subject.execute(rss_page1, context)
            end

            expect(Article::Page.count).to eq 1
            Article::Page.first.tap do |page|
              expect(page.name).to eq '福岡県土砂災害警戒情報'
              expect(page.state).to eq subject.publish_state
              expect(page.category_ids).to eq [ category_node.id ]
              expect(page.html).to include('<div class="jmaxml landslide">')
              expect(page.html).to include('<time datetime="2013-08-31T11:05:17+09:00">2013年8月31日 11時05分</time>')
              expect(page.html).to include('<span class="publishing-office">福岡県・福岡管区気象台　共同発表</span>')
              expect(page.html).to include("<p>#{headline_text}")
              expect(page.html).to include('<div class="warning published">')
              expect(page.html).to include('<h3>警戒（発表）</h3>')
              expect(page.html).to include('<li>北九州市</li>')
              expect(page.html).to include('<li>福岡市</li>')

              expect(page.html).to include('<div class="warning continued">')
              expect(page.html).to include('<h3>警戒（継続）</h3>')
              expect(page.html).to include('<li>直方市</li>')
              expect(page.html).to include('<li>飯塚市</li>')

              expect(page.html).to include('<div class="warning canceled">')
              expect(page.html).to include('<h3>解除</h3>')
              expect(page.html).to include('<li>大牟田市</li>')
              expect(page.html).to include('<li>久留米市</li>')
            end
          end
        end

        context 'when volcano flash is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_67_01_150514_VFVO56-1.xml))) }
          let(:trigger) { create(:jmaxml_trigger_volcano_flash) }

          before do
            region1 = create(:jmaxml_forecast_region_2042900)
            region2 = create(:jmaxml_forecast_region_2043200)
            trigger.target_region_ids = [ region1.id, region2.id ]
            trigger.save!

            subject.publish_to_id = article_node.id
            subject.category_ids = [ category_node.id ]
            subject.save!
          end

          it do
            trigger.verify(rss_page1, context) do
              subject.execute(rss_page1, context)
            end

            expect(Article::Page.count).to eq 1
            Article::Page.first.tap do |page|
              expect(page.name).to eq '火山名　御嶽山　噴火速報'
              expect(page.state).to eq subject.publish_state
              expect(page.category_ids).to eq [ category_node.id ]
              expect(page.html).to include('<div class="jmaxml volcano">')
              expect(page.html).to include('<time datetime="2014-09-27T12:00:12+09:00">2014年9月27日 12時00分</time>')
              expect(page.html).to include('<span class="publishing-office">気象庁地震火山部発表</span>')
              expect(page.html).to include('<strong>御嶽山で噴火が発生</strong><br />')
              expect(page.html).to include('御嶽山で、平成２６年９月２７日１１時５３分頃、噴火が発生しました。')
              expect(page.html).to include('<li>長野県王滝村</li>')
              expect(page.html).to include('<li>長野県木曽町</li>')
            end
          end
        end

        context 'when ash fall forecast is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_66_01_141024_VFVO53.xml))) }
          let(:trigger) { create(:jmaxml_trigger_ash_fall_forecast) }

          before do
            region_4620100 = create(:jmaxml_forecast_region_4620100)
            region_4620300 = create(:jmaxml_forecast_region_4620300)
            region_4621400 = create(:jmaxml_forecast_region_4621400)
            region_4621700 = create(:jmaxml_forecast_region_4621700)
            trigger.target_region_ids = [ region_4620100.id, region_4620300.id, region_4621400.id, region_4621700.id ]
            trigger.save!

            subject.publish_to_id = article_node.id
            subject.category_ids = [ category_node.id ]
            subject.save!
          end

          it do
            trigger.verify(rss_page1, context) do
              subject.execute(rss_page1, context)
            end

            expect(Article::Page.count).to eq 1
            Article::Page.first.tap do |page|
              expect(page.name).to eq '火山名　桜島　降灰予報（定時）'
              expect(page.state).to eq subject.publish_state
              expect(page.category_ids).to eq [ category_node.id ]
              expect(page.html).to include('<div class="jmaxml ashfall">')
              expect(page.html).to include('<time datetime="2014-06-06T05:00:00+09:00">2014年6月6日 05時00分</time>')
              expect(page.html).to include('<span class="publishing-office">気象庁地震火山部発表</span>')
              expect(page.html).to include('<p>　現在、桜島は噴火警戒レベル３（入山規制）です。')
              expect(page.html).to include('<dt>降灰</dt>')
              expect(page.html).to include('<li>鹿児島県鹿児島市</li>')
              expect(page.html).to include('<li>鹿児島県鹿屋市</li>')
              expect(page.html).to include('<dt>小さな噴石の落下</dt>')
              expect(page.html).to include('<li>鹿児島県鹿児島市</li>')
              expect(page.html).to include('<p>　６日０６時から６日２４時までに噴火が発生した場合には、')
              expect(page.html).to include('<p>　噴煙が高さ３０００ｍまで上がった場合の火山灰')
            end
          end
        end

        context 'when tornado alert is given' do
          let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_19_01_091210_tatsumakijyohou1.xml))) }
          let(:trigger) { create(:jmaxml_trigger_tornado_alert) }

          before do
            region_1310100 = create(:jmaxml_forecast_region_1310100)
            region_1310200 = create(:jmaxml_forecast_region_1310200)
            region_1310300 = create(:jmaxml_forecast_region_1310300)
            region_1310400 = create(:jmaxml_forecast_region_1310400)
            trigger.target_region_ids = [ region_1310100.id, region_1310200.id, region_1310300.id, region_1310400.id ]
            trigger.save!

            subject.publish_to_id = article_node.id
            subject.category_ids = [ category_node.id ]
            subject.save!
          end

          it do
            trigger.verify(rss_page1, context) do
              subject.execute(rss_page1, context)
            end

            expect(Article::Page.count).to eq 1
            Article::Page.first.tap do |page|
              expect(page.name).to eq '東京都竜巻注意情報'
              expect(page.state).to eq subject.publish_state
              expect(page.category_ids).to eq [ category_node.id ]
              expect(page.html).to include('<div class="jmaxml tornado">')
              expect(page.html).to include('<time datetime="2009-08-10T07:38:00+09:00">2009年8月10日 07時38分</time>')
              expect(page.html).to include('<span class="publishing-office">気象庁予報部発表</span>')
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
      let!(:rss_page1) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, in_xml: xml1) }
      let!(:rss_page2) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, in_xml: xml2) }
      let!(:article_node) { create(:article_node_page) }
      let!(:category_node) { create(:category_node_page, cur_node: article_node) }
      let(:context) { OpenStruct.new(site: site, node: rss_node, xmldoc: xmldoc) }
      subject { create(:jmaxml_action_publish_page) }

      around do |example|
        Timecop.travel(report_time) do
          example.run
        end
      end

      context 'when quake intensity flash is canceled' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_01shindosokuhou3.xml))) }
        let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_99shindosokuhou3.xml))) }
        let(:trigger) { create(:jmaxml_trigger_quake_intensity_flash) }

        before do
          region_210 = create(:jmaxml_region_210)
          region_211 = create(:jmaxml_region_211)
          region_212 = create(:jmaxml_region_212)
          region_213 = create(:jmaxml_region_213)
          trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
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
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml cancel quake">')
            expect(page.html).to include('<time datetime="2011-03-11T14:48:10+09:00">2011年3月11日 14時48分</time>')
            expect(page.html).to include('<span class="publishing-office">気象庁発表</span>')
            expect(page.html).to include('<p>緊急地震速報（警報）を取り消します。</p>')
          end
        end
      end

      context 'when quake info is canceled' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-35_06_100915_03zenkokusaisumo1.xml))) }
        let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-35_06_100915_06zenkokusaisumo1.xml))) }
        let(:trigger) { create(:jmaxml_trigger_quake_info) }

        before do
          region_210 = create(:jmaxml_region_210)
          region_211 = create(:jmaxml_region_211)
          region_212 = create(:jmaxml_region_212)
          region_213 = create(:jmaxml_region_213)
          trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
          subject.save!
        end

        it do
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '【取消】震源・震度情報'
            expect(page.state).to eq subject.publish_state
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml cancel quake">')
            expect(page.html).to include('<time datetime="2008-06-14T09:06:34+09:00">2008年6月14日 09時06分</time>')
            expect(page.html).to include('<span class="publishing-office">気象庁発表</span>')
            expect(page.html).to include('<p>震源・震度情報を取り消します。</p>')
          end
        end
      end

      context 'when volcano flash is canceled' do
        let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_67_01_150514_VFVO56-1.xml))) }
        let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_67_01_150514_VFVO56-4.xml))) }
        let(:trigger) { create(:jmaxml_trigger_volcano_flash) }

        before do
          region1 = create(:jmaxml_forecast_region_2042900)
          region2 = create(:jmaxml_forecast_region_2043200)
          trigger.target_region_ids = [ region1.id, region2.id ]
          trigger.save!

          subject.publish_to_id = article_node.id
          subject.category_ids = [ category_node.id ]
          subject.save!
        end

        it do
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          expect(Article::Page.count).to eq 1
          Article::Page.first.tap do |page|
            expect(page.name).to eq '【取消】火山名　御嶽山　噴火速報'
            expect(page.state).to eq subject.publish_state
            expect(page.category_ids).to eq [ category_node.id ]
            expect(page.html).to include('<div class="jmaxml cancel volcano">')
            expect(page.html).to include('<time datetime="2014-09-27T12:10:12+09:00">2014年9月27日 12時10分</time>')
            expect(page.html).to include('<span class="publishing-office">気象庁地震火山部発表</span>')
            expect(page.html).to include('<p>噴火速報を取り消します。</p>')
          end
        end
      end
    end
  end
end
