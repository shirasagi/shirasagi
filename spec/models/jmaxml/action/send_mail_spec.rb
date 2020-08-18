require 'spec_helper'

describe Jmaxml::Action::SendMail, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_action_send_mail) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:sender_name) { is_expected.not_to be_nil }
    its(:sender_email) { is_expected.to eq "#{subject.sender_name}@example.jp" }
    its(:signature_text) { is_expected.not_to be_nil }
  end

  describe '#execute' do
    let!(:group1) { create(:cms_group, name: unique_id) }
    let!(:group2) { create(:cms_group, name: unique_id) }
    let!(:group3) { create(:cms_group, name: unique_id) }
    let!(:user1) { create(:cms_test_user, group_ids: [ group1.id ]) }
    let!(:user2) { create(:cms_test_user, group_ids: [ group2.id ]) }
    let!(:user3) { create(:cms_test_user, group_ids: [ group2.id ]) }
    let!(:user4) { create(:cms_test_user, group_ids: [ group1.id, group3.id ]) }
    subject { create(:jmaxml_action_send_mail) }

    before do
      ActionMailer::Base.deliveries = []
    end

    after do
      ActionMailer::Base.deliveries = []
    end

    before do
      subject.recipient_user_ids = [ user1.id ]
      subject.recipient_group_ids = [ group2.id, group3.id ]
      subject.save!
    end

    around do |example|
      Timecop.travel(report_time) do
        example.run
      end
    end

    context 'when alert/info is received' do
      let(:xmldoc) { REXML::Document.new(xml1) }
      let(:report_time) { REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
      let(:target_time) { REXML::XPath.first(xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip }
      let(:event_id) { REXML::XPath.first(xmldoc, '/Report/Head/EventID/text()').to_s.strip }
      let(:rss_node) { create(:rss_node_weather_xml) }
      let!(:rss_page1) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, in_xml: xml1) }
      let(:context) { OpenStruct.new(site: site, node: rss_node, xmldoc: xmldoc) }

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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first.to_s).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '震度速報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2011年3月11日 14時48分　気象庁発表')
            expect(mail.body.raw_source).to include('2011年3月11日 14時46分ごろ地震がありました。')
            expect(mail.body.raw_source).to include('岩手県沿岸南部：震度６弱')
            expect(mail.body.raw_source).to include('岩手県内陸南部：震度６弱')
            expect(mail.body.raw_source).to include('岩手県沿岸北部：震度５強')
            expect(mail.body.raw_source).to include('岩手県内陸北部：震度５強')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '震源・震度情報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2008年6月14日 08時47分　気象庁発表')
            expect(mail.body.raw_source).to include('2008年6月14日 08時43分ごろ地震がありました。')
            expect(mail.body.raw_source).to include('岩手県内陸南部：震度６強')
            expect(mail.body.raw_source).to include('岩手県沿岸北部：震度４')
            expect(mail.body.raw_source).to include('岩手県沿岸南部：震度４')
            expect(mail.body.raw_source).to include('岩手県内陸北部：震度４')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
          region_210 = create(:jmaxml_tsunami_region_210)
          trigger.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id, region_210.id ]
          trigger.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '大津波警報・津波警報・津波注意報・津波予報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('東日本大震災クラスの津波が来襲します。')
            expect(mail.body.raw_source).to include('岩手県　　　　　　　　　　第１波：津波到達中と推測')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸中部　　　第１波：2011年3月11日 15時30分')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸東部　　　第１波：2011年3月11日 15時30分')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸西部　　　第１波：2011年3月11日 15時40分')
            expect(mail.body.raw_source).to include('地震発生時刻：　　2011年3月11日 14時46分ごろ')
            expect(mail.body.raw_source).to include('震源地：　　　　　三陸沖 牡鹿半島の東南東１３０ｋｍ付近')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
          region_201 = create(:jmaxml_tsunami_region_201)
          trigger.target_region_ids = [ region_100.id, region_101.id, region_102.id, region_110.id, region_201.id ]
          trigger.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '各地の満潮時刻・津波到達予想時刻に関する情報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('各地の満潮時刻と津波到達予想時刻をお知らせします。')
            expect(mail.body.raw_source).to include('青森県太平洋沿岸　　　　　第１波：2010年2月28日 13時30分　高さ：３ｍ')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸東部　　　第１波：2010年2月28日 13時00分　高さ：２ｍ')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸中部　　　第１波：2010年2月28日 13時30分　高さ：２ｍ')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸西部　　　第１波：2010年2月28日 14時00分　高さ：１ｍ')
            expect(mail.body.raw_source).to include('地震発生時刻：　　2010年2月27日 15時34分ごろ')
            expect(mail.body.raw_source).to include('震源地：　　　　　南米西部')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '奈良県気象警報・注意報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2011年9月4日 00時10分　奈良地方気象台発表')
            expect(mail.body.raw_source).to include('【特別警報（大雨）】奈良県では、４日昼過ぎまで土砂災害に、４日朝まで低い土地の浸水や河川の増水に警戒して下さい。')
            expect(mail.body.raw_source).to include('＜奈良市＞')
            expect(mail.body.raw_source).to include('大雨特別警報、雷注意報、強風注意報、洪水注意報')
            expect(mail.body.raw_source).to include('＜大和高田市＞')
            expect(mail.body.raw_source).to include('＜大和郡山市＞')
            expect(mail.body.raw_source).to include('＜天理市＞')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '揖斐川中流はん濫注意情報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2008年9月3日 04時15分　木曽川上流河川事務所・岐阜地方気象台　共同発表')
            expect(mail.body.raw_source).to include(main_sentence)
            expect(mail.body.raw_source).to include('＜岐阜県△△市＞')
            expect(mail.body.raw_source).to include('△△地区 △△地区 △△地区')
            expect(mail.body.raw_source).to include('所により１時間に５０ミリの雨が降っています。')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
          "＜概況＞\n　降り続く大雨のため、警戒対象地域では土砂災害の危険度が高まっています。\n\n＜とるべき措置＞\n　崖の近くなど土砂災害の発生しやすい地区にお住まいの方は、"
        end

        before do
          target_region_ids = []
          area_codes.each do |area_code|
            region = create("jmaxml_forecast_region_#{area_code}".to_sym)
            target_region_ids << region.id
          end
          trigger.target_region_ids = target_region_ids
          trigger.save!
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '福岡県土砂災害警戒情報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2013年8月31日 11時05分　福岡県・福岡管区気象台　共同発表')
            expect(mail.body.raw_source).to include(headline_text)
            expect(mail.body.raw_source).to include("＜警戒（発表）＞\n北九州市、福岡市")
            expect(mail.body.raw_source).to include("＜警戒（継続）＞\n直方市、飯塚市、田川市、行橋市、筑紫野市")
            expect(mail.body.raw_source).to include("＜解除＞\n大牟田市、久留米市、八女市、中間市、小郡市")
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '火山名　御嶽山　噴火速報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2014年9月27日 12時00分　気象庁地震火山部発表')
            expect(mail.body.raw_source).to include('御嶽山で、平成２６年９月２７日１１時５３分頃、噴火が発生しました。')
            expect(mail.body.raw_source).to include("長野県王滝村、長野県木曽町")
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '火山名　桜島　降灰予報（定時）'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2014年6月6日 05時00分　気象庁地震火山部発表')
            expect(mail.body.raw_source).to include("＜降灰＞\n鹿児島県鹿児島市、鹿児島県鹿屋市、")
            expect(mail.body.raw_source).to include("＜小さな噴石の落下＞\n鹿児島県鹿児島市")
            expect(mail.body.raw_source).to include('６日０６時から６日２４時までに噴火が発生した場合には、')
            expect(mail.body.raw_source).to include('６日０６時から０９時まで　南東（垂水・鹿屋方向）')
            expect(mail.body.raw_source).to include('噴煙が高さ３０００ｍまで上がった場合の')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '東京都竜巻注意情報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2009年8月10日 07時38分　気象庁予報部発表')
            expect(mail.body.raw_source).to include("東京地方では、竜巻発生のおそれがあります。")
            expect(mail.body.raw_source).to include("千代田区、中央区、港区、新宿区")
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
      let(:context) { OpenStruct.new(site: site, node: rss_node, xmldoc: xmldoc) }

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
        end

        it do
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '【取消】震度速報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2011年3月11日 14時46分　気象庁発表')
            expect(mail.body.raw_source).to include('緊急地震速報（警報）を取り消します。')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '【取消】震源・震度情報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2008年6月14日 09時06分　気象庁発表')
            expect(mail.body.raw_source).to include('震源・震度情報を取り消します。')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
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
        end

        it do
          trigger.verify(rss_page2, context) do
            subject.execute(rss_page2, context)
          end

          mail_subject = nil
          mail_body = nil
          emails = [ user1.email, user2.email, user3.email, user4.email ]
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            emails.delete(mail.to.first)
            expect(mail.subject).to eq '【取消】火山名　御嶽山　噴火速報'
            mail_subject ||= mail.subject
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2014年9月27日 11時53分　気象庁地震火山部発表')
            expect(mail.body.raw_source).to include('噴火速報を取り消します。')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          expect(emails).to eq []
        end
      end
    end
  end
end
