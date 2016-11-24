require 'spec_helper'

describe Jmaxml::Action::SendMail, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_action_send_mail) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:sender_name) { is_expected.not_to be_nil }
    its(:sender_email) { is_expected.to eq "#{subject.sender_name}@example.jp" }
    its(:signature_text) { is_expected.to end_with "#{subject.sender_name}@example.jp" }
  end

  describe '#execute' do
    let!(:group1) { create(:cms_group, name: unique_id) }
    let!(:group2) { create(:cms_group, name: unique_id) }
    let!(:group3) { create(:cms_group, name: unique_id) }
    let!(:user1) { create(:cms_test_user, group_ids: [ group1.id ]) }
    let!(:user2) { create(:cms_test_user, group_ids: [ group2.id ]) }
    let!(:user3) { create(:cms_test_user, group_ids: [ group2.id ]) }
    let!(:user4) { create(:cms_test_user, group_ids: [ group1.id, group3.id ]) }
    let(:emails) { [ user1.email, user2.email, user3.email, user4.email ] }
    subject { create(:jmaxml_action_send_mail) }

    before do
      ActionMailer::Base.deliveries = []
    end

    after do
      ActionMailer::Base.deliveries = []
    end

    before do
      subject.user_ids = [ user1.id ]
      subject.group_ids = [ group2.id, group3.id ]
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
      let!(:rss_page1) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, xml: xml1) }
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

          mail_body = nil
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            expect(mail.subject).to eq '震度速報'
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2011年3月11日 14時46分ごろ地震がありました。')
            expect(mail.body.raw_source).to include('岩手県沿岸南部：震度 6弱')
            expect(mail.body.raw_source).to include('岩手県内陸南部：震度 6弱')
            expect(mail.body.raw_source).to include('岩手県沿岸北部：震度 5強')
            expect(mail.body.raw_source).to include('岩手県内陸北部：震度 5強')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          puts mail_body
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

          mail_body = nil
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            expect(mail.subject).to eq '震源・震度に関する情報'
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('2008年6月14日 08時47分ごろ地震がありました。')
            expect(mail.body.raw_source).to include('岩手県内陸南部：震度 6強')
            expect(mail.body.raw_source).to include('岩手県沿岸北部：震度 4')
            expect(mail.body.raw_source).to include('岩手県沿岸南部：震度 4')
            expect(mail.body.raw_source).to include('岩手県内陸北部：震度 4')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          puts mail_body
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_body = nil
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            expect(mail.subject).to eq '大津波警報・津波警報・津波注意報・津波予報'
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('東日本大震災クラスの津波が来襲します。')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸中部：津波警報　第1波 2011年3月11日 15時30分　高さ')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸東部：津波注意報　第1波 2011年3月11日 15時30分　高さ')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸西部：津波注意報　第1波 2011年3月11日 15時40分　高さ')
            expect(mail.body.raw_source).to include('地震発生時刻：2011年3月11日 14時46分')
            expect(mail.body.raw_source).to include('震源地：三陸沖 牡鹿半島の東南東１３０ｋｍ付近')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          puts mail_body
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
        end

        it do
          trigger.verify(rss_page1, context) do
            subject.execute(rss_page1, context)
          end

          mail_body = nil
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            expect(mail.subject).to eq '各地の満潮時刻・津波到達予想時刻に関する情報'
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('各地の満潮時刻と津波到達予想時刻をお知らせします。')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸東部：津波の津波警報　第1波 2010年2月28日 13時00分　高さ 2m')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸中部：津波の津波警報　第1波 2010年2月28日 13時30分　高さ 2m')
            expect(mail.body.raw_source).to include('北海道太平洋沿岸西部：津波の津波警報　第1波 2010年2月28日 14時00分　高さ 1m')
            expect(mail.body.raw_source).to include('北海道日本海沿岸北部：津波予報（若干の海面変動）　第1波 　高さ 0.2m')
            expect(mail.body.raw_source).to include('地震発生時刻：2010年2月27日 15時34分')
            expect(mail.body.raw_source).to include('震源地：南米西部')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end
          puts mail_body
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

          mail_body = nil
          expect(ActionMailer::Base.deliveries.length).to eq 4
          ActionMailer::Base.deliveries.each do |mail|
            expect(mail).not_to be_nil
            expect(mail.from).to eq [ subject.sender_email ]
            expect(mail.to.first).to be_in(emails)
            expect(mail.subject).to eq '【取消】震度速報'
            mail_body ||= mail.body.raw_source
            expect(mail.body.raw_source).to include('緊急地震速報（警報）を取り消します。')
            expect(mail.body.raw_source).to end_with("\n#{subject.signature_text}\n")
          end

          puts mail_body
        end
      end
    end
  end
end
