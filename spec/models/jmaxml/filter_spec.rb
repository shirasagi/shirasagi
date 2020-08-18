require 'spec_helper'

describe Jmaxml::Filter, dbscope: :example do
  let(:site) { cms_site }

  let!(:group1) { create(:cms_group, name: unique_id) }
  let!(:user1) { create(:cms_test_user, group_ids: [ group1.id ]) }

  let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_01shindosokuhou3.xml))) }
  let(:xmldoc) { REXML::Document.new(xml1) }
  let(:report_time) { REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip }
  let(:target_time) { REXML::XPath.first(xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip }
  let(:event_id) { REXML::XPath.first(xmldoc, '/Report/Head/EventID/text()').to_s.strip }
  let(:rss_node) { create(:rss_node_weather_xml) }
  let!(:rss_page1) { create(:rss_weather_xml_page, cur_node: rss_node, event_id: event_id, in_xml: xml1) }
  let!(:article_node) { create(:article_node_page) }
  let!(:category_node) { create(:category_node_page, cur_node: article_node) }
  let(:context) { OpenStruct.new(site: site, node: rss_node) }
  let(:trigger) { create(:jmaxml_trigger_quake_intensity_flash) }
  let(:action1) { create(:jmaxml_action_publish_page, publish_to_id: article_node.id, category_ids: [ category_node.id ]) }
  let(:action2) { create(:jmaxml_action_send_mail, recipient_user_ids: [ user1.id ]) }

  let(:filter) { rss_node.filters.first }

  around do |example|
    Timecop.travel(report_time) do
      example.run
    end
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  before do
    region_210 = create(:jmaxml_region_210)
    region_211 = create(:jmaxml_region_211)
    region_212 = create(:jmaxml_region_212)
    region_213 = create(:jmaxml_region_213)
    trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
    trigger.save!

    rss_node.filters.new(
      name: unique_id, state: 'enabled', trigger_ids: [ trigger.id.to_s ],
      action_ids: [ action1.id.to_s, action2.id.to_s ])
    rss_node.save!
  end

  it do
    filter.execute(rss_page1, context)

    expect(Article::Page.count).to eq 1
    Article::Page.first.tap do |page|
      expect(page.name).to eq '震度速報'
      expect(page.state).to eq action1.publish_state
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

    expect(ActionMailer::Base.deliveries.length).to eq 1
    ActionMailer::Base.deliveries.first.tap do |mail|
      expect(mail).not_to be_nil
      expect(mail.from).to eq [ action2.sender_email ]
      expect(mail.to.first.to_s).to eq user1.email
      expect(mail.subject).to eq '震度速報'
      expect(mail.body.raw_source).to include('2011年3月11日 14時48分　気象庁発表')
      expect(mail.body.raw_source).to include('2011年3月11日 14時46分ごろ地震がありました。')
      expect(mail.body.raw_source).to include('岩手県沿岸南部：震度６弱')
      expect(mail.body.raw_source).to include('岩手県内陸南部：震度６弱')
      expect(mail.body.raw_source).to include('岩手県沿岸北部：震度５強')
      expect(mail.body.raw_source).to include('岩手県内陸北部：震度５強')
      expect(mail.body.raw_source).to end_with("\n#{action2.signature_text}\n")
    end
  end
end
