require 'spec_helper'

describe Rss::ImportWeatherXmlJob, dbscope: :example do
  after(:all) do
    WebMock.reset!
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  context "when importing weather sample xml" do
    let(:site) { cms_site }
    let(:filepath) { Rails.root.join(*%w(spec fixtures jmaxml weather-sample.xml)) }
    let(:node) { create(:rss_node_weather_xml, cur_site: site, page_state: 'closed') }
    let(:file) { Rss::TempFile.create_from_post(site, File.read(filepath), 'application/xml+rss') }
    let(:model) { Rss::WeatherXmlPage }
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml afeedc52-107a-3d1d-9196-b108234d6e0f.xml))) }
    let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 2b441518-4e79-342c-a271-7c25597f3a69.xml))) }

    before do
      stub_request(:get, 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').
        to_return(body: xml1, status: 200, headers: { 'Content-Type' => 'application/xml' })
      stub_request(:get, 'http://xml.kishou.go.jp/data/2b441518-4e79-342c-a271-7c25597f3a69.xml').
        to_return(body: xml2, status: 200, headers: { 'Content-Type' => 'application/xml' })
    end

    it do
      expect { described_class.bind(site_id: site, node_id: node).perform_now(file.id) }.to change { model.count }.from(0).to(2)
      item = model.where(rss_link: 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').first
      expect(item).not_to be_nil
      expect(item.name).to eq '気象警報・注意報'
      expect(item.rss_link).to eq 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml'
      expect(item.html).to eq '【福島県気象警報・注意報】注意報を解除します。'
      expect(item.released).to eq Time.zone.parse('2016-03-10T09:22:41Z')
      expect(item.authors.count).to eq 1
      expect(item.authors.first.name).to eq '福島地方気象台'
      expect(item.authors.first.email).to be_nil
      expect(item.authors.first.uri).to be_nil
      expect(item.event_id).to eq '20160318182200_984'
      expect(item.xml).not_to be_nil
      expect(item.xml).to include('<InfoKind>気象警報・注意報</InfoKind>')
      expect(item.state).to eq 'closed'

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end
    end
  end

  context "when importing earthquake sample xml and sending anpi mail" do
    let(:site) { cms_site }
    let(:filepath) { Rails.root.join(*%w(spec fixtures jmaxml earthquake-sample-1.xml)) }
    let(:node) do
      create(
        :rss_node_weather_xml,
        cur_site: site,
        page_state: 'closed',
        title_mail_text: "\#{target_time} ころ地震がありました",
        upper_mail_text: "\#{target_time} ころ地震がありました。\n\n各地の震度は下記の通りです。\n",
        lower_mail_text: "下記のアドレスにアクセスし、安否情報を入力してください。\n\#{anpi_post_url}\n",
        loop_mail_text: "\#{area_name}：\#{intensity_label}\n")
    end
    let(:node_ezine_member_page) do
      create(
        :ezine_node_member_page,
        cur_site: site,
        sender_name: 'test',
        sender_email: 'test@example.jp',
        signature_html: '<br>--------<br>test@example.jp<br>',
        signature_text: "\n--------\ntest@example.jp\n")
    end
    let(:node_my_anpi_post) { create(:member_node_my_anpi_post, cur_site: site) }
    let(:file) { Rss::TempFile.create_from_post(site, File.read(filepath), 'application/xml+rss') }
    let(:model) { Rss::WeatherXmlPage }
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 9b43a982-fecf-3866-95e7-c375226a7c87.xml))) }

    before do
      stub_request(:get, 'http://xml.kishou.go.jp/data/9b43a982-fecf-3866-95e7-c375226a7c87.xml').
        to_return(body: xml1, status: 200, headers: { 'Content-Type' => 'application/xml' })
    end

    before do
      id = node_ezine_member_page.id
      10.times do |i|
        create(:cms_member, subscription_ids: [ id ], email_type: %w(text html)[i % 2])
      end
    end

    before do
      region_152 = create(:jmaxml_region_152)
      node.target_region_ids = [ region_152.id ]
      node.earthquake_intensity = '3'
      node.my_anpi_post_id = node_my_anpi_post.id
      node.anpi_mail_id = node_ezine_member_page.id
      node.save!
    end

    around do |example|
      Timecop.travel('2016-03-08T04:36:00Z') do
        example.run
      end
    end

    it do
      expect { described_class.bind(site_id: site, node_id: node).perform_now(file.id) }.to change { model.count }.from(0).to(1)
      item = model.where(rss_link: 'http://xml.kishou.go.jp/data/9b43a982-fecf-3866-95e7-c375226a7c87.xml').first
      expect(item).not_to be_nil
      expect(item.name).to eq '震度速報'
      expect(item.rss_link).to eq 'http://xml.kishou.go.jp/data/9b43a982-fecf-3866-95e7-c375226a7c87.xml'
      expect(item.html).to eq '【震度速報】　８日１３時３２分ころ、地震による強い揺れを感じました。震度３以上が観測された地域をお知らせします。'
      expect(item.released).to eq Time.zone.parse('2016-03-08T04:34:18Z')
      expect(item.authors.count).to eq 1
      expect(item.authors.first.name).to eq '気象庁'
      expect(item.authors.first.email).to be_nil
      expect(item.authors.first.uri).to be_nil
      expect(item.event_id).to eq '20160308133250'
      expect(item.xml).not_to be_nil
      expect(item.xml).to include('<InfoKind>震度速報</InfoKind>')
      expect(item.state).to eq 'closed'

      expect(Job::Log.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      expect(ActionMailer::Base.deliveries.length).to eq 10

      ActionMailer::Base.deliveries.each do |mail|
        expect(mail).not_to be_nil
        expect(mail.from.first).to eq "test@example.jp"
        expect(Cms::Member.site(site).map(&:email)).to include mail.to.first
        expect(mail.subject).to eq '2016年3月8日 13時32分 ころ地震がありました'
        expect(mail.body.raw_source).to include('2016年3月8日 13時32分 ころ地震がありました。')
        expect(mail.body.raw_source).to include('日高地方東部：3')
        expect(mail.body.raw_source).to include(node_my_anpi_post.full_url)
        expect(mail.body.raw_source).to end_with("\n--------\ntest@example.jp\n")
      end
    end
  end

  context "when 2011 tohoku earthquake is given" do
    context "when apni confirmation mails are sent" do
      let(:site) { cms_site }
      let(:filepath) { Rails.root.join(*%w(spec fixtures jmaxml earthquake-sample-2.xml)) }
      let(:node) do
        create(
          :rss_node_weather_xml,
          cur_site: site,
          page_state: 'closed',
          title_mail_text: "\#{target_time} ころ地震がありました",
          upper_mail_text: "\#{target_time} ころ地震がありました。\n\n各地の震度は下記の通りです。\n",
          lower_mail_text: "下記のアドレスにアクセスし、安否情報を入力してください。\n\#{anpi_post_url}\n",
          loop_mail_text: "\#{area_name}：\#{intensity_label}\n")
      end
      let(:node_ezine_member_page) do
        create(
          :ezine_node_member_page,
          cur_site: site,
          sender_name: 'test',
          sender_email: 'test@example.jp',
          signature_html: '<br>--------<br>test@example.jp<br>',
          signature_text: "\n--------\ntest@example.jp\n")
      end
      let(:node_my_anpi_post) { create(:member_node_my_anpi_post, cur_site: site) }
      let(:file) { Rss::TempFile.create_from_post(site, File.read(filepath), 'application/xml+rss') }
      let(:model) { Rss::WeatherXmlPage }
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_01shindosokuhou3.xml))) }

      before do
        stub_request(:get, 'http://xml.kishou.go.jp/data/70_32-39_11_120615_01shindosokuhou3.xml').
          to_return(body: xml1, status: 200, headers: { 'Content-Type' => 'application/xml' })
      end

      before do
        id = node_ezine_member_page.id
        10.times do |i|
          create(:cms_member, subscription_ids: [ id ], email_type: %w(text html)[i % 2])
        end
      end

      before do
        region_210 = create(:jmaxml_region_210)
        region_211 = create(:jmaxml_region_211)
        region_212 = create(:jmaxml_region_212)
        region_213 = create(:jmaxml_region_213)
        node.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
        node.earthquake_intensity = '5+'
        node.my_anpi_post_id = node_my_anpi_post.id
        node.anpi_mail_id = node_ezine_member_page.id
        node.save!
      end

      around do |example|
        Timecop.travel('2011-03-11T05:50:00Z') do
          example.run
        end
      end

      it do
        expect { described_class.bind(site_id: site, node_id: node).perform_now(file.id) }.to change { model.count }.from(0).to(1)
        item = model.where(rss_link: 'http://xml.kishou.go.jp/data/70_32-39_11_120615_01shindosokuhou3.xml').first
        expect(item).not_to be_nil
        expect(item.name).to eq '震度速報'
        expect(item.rss_link).to eq 'http://xml.kishou.go.jp/data/70_32-39_11_120615_01shindosokuhou3.xml'
        expect(item.html).to eq '【震度速報】１１日１４時４６分ころ、地震による強い揺れを感じました。震度３以上が観測された地域をお知らせします。'
        expect(item.released).to eq Time.zone.parse('2011-03-11T05:48:10Z')
        expect(item.authors.count).to eq 1
        expect(item.authors.first.name).to eq '気象庁'
        expect(item.authors.first.email).to be_nil
        expect(item.authors.first.uri).to be_nil
        expect(item.event_id).to eq '20110311144640'
        expect(item.xml).not_to be_nil
        expect(item.xml).to include('<InfoKind>震度速報</InfoKind>')
        expect(item.state).to eq 'closed'

        expect(Job::Log.count).to eq 2
        Job::Log.all.each do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end

        expect(ActionMailer::Base.deliveries.length).to eq 10

        ActionMailer::Base.deliveries.each do |mail|
          expect(mail).not_to be_nil
          expect(mail.from.first).to eq "test@example.jp"
          expect(Cms::Member.site(site).map(&:email)).to include mail.to.first
          expect(mail.subject).to eq '2011年3月11日 14時46分 ころ地震がありました'
          expect(mail.body.raw_source).to include('2011年3月11日 14時46分 ころ地震がありました。')
          expect(mail.body.raw_source).to include('岩手県沿岸南部：6弱')
          expect(mail.body.raw_source).to include('岩手県内陸南部：6弱')
          expect(mail.body.raw_source).to include('岩手県沿岸北部：5強')
          expect(mail.body.raw_source).to include('岩手県内陸北部：5強')
          expect(mail.body.raw_source).to include(node_my_anpi_post.full_url)
          expect(mail.body.raw_source).to end_with("\n--------\ntest@example.jp\n")
        end
      end
    end

    context "when filters are executed" do
      let(:site) { cms_site }
      let(:filepath) { Rails.root.join(*%w(spec fixtures jmaxml earthquake-sample-2.xml)) }
      let(:node) { create(:rss_node_weather_xml, cur_site: site, page_state: 'closed') }
      let(:file) { Rss::TempFile.create_from_post(site, File.read(filepath), 'application/xml+rss') }
      let(:model) { Rss::WeatherXmlPage }
      let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 70_32-39_11_120615_01shindosokuhou3.xml))) }

      let(:trigger1) { create(:jmaxml_trigger_quake_intensity_flash) }
      let(:trigger2) { create(:jmaxml_trigger_quake_info) }

      let(:article_node) { create(:article_node_page) }
      let(:category_node) { create(:category_node_page) }
      let(:action1) { create(:jmaxml_action_publish_page, publish_to_id: article_node.id, category_ids: [ category_node.id ]) }

      let(:group1) { create(:cms_group, name: "#{cms_group.name}/#{unique_id}") }
      let(:user1) { create(:cms_test_user, group_ids: [ group1.id ]) }
      let(:action2) { create(:jmaxml_action_send_mail, recipient_user_ids: [ user1.id ]) }

      before do
        stub_request(:get, 'http://xml.kishou.go.jp/data/70_32-39_11_120615_01shindosokuhou3.xml').
            to_return(body: xml1, status: 200, headers: { 'Content-Type' => 'application/xml' })
      end

      before do
        region_210 = create(:jmaxml_region_210)
        region_211 = create(:jmaxml_region_211)
        region_212 = create(:jmaxml_region_212)
        region_213 = create(:jmaxml_region_213)
        trigger1.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
        trigger1.save!
        trigger2.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
        trigger2.save!

        node.filters.new(name: unique_id, state: 'enabled', trigger_ids: [ trigger1.id.to_s ],
          action_ids: [ action1.id.to_s, action2.id.to_s ])
        node.filters.new(name: unique_id, state: 'enabled', trigger_ids: [ trigger2.id.to_s ],
          action_ids: [ action1.id.to_s, action2.id.to_s ])
        node.save!
      end

      around do |example|
        Timecop.travel('2011-03-11T05:50:00Z') do
          example.run
        end
      end

      it do
        expect { described_class.bind(site_id: site, node_id: node).perform_now(file.id) }.to change { model.count }.from(0).to(1)
        item = model.where(rss_link: 'http://xml.kishou.go.jp/data/70_32-39_11_120615_01shindosokuhou3.xml').first
        expect(item).not_to be_nil
        expect(item.name).to eq '震度速報'
        expect(item.rss_link).to eq 'http://xml.kishou.go.jp/data/70_32-39_11_120615_01shindosokuhou3.xml'
        expect(item.html).to eq '【震度速報】１１日１４時４６分ころ、地震による強い揺れを感じました。震度３以上が観測された地域をお知らせします。'
        expect(item.released).to eq Time.zone.parse('2011-03-11T05:48:10Z')
        expect(item.authors.count).to eq 1
        expect(item.authors.first.name).to eq '気象庁'
        expect(item.authors.first.email).to be_nil
        expect(item.authors.first.uri).to be_nil
        expect(item.event_id).to eq '20110311144640'
        expect(item.xml).not_to be_nil
        expect(item.xml).to include('<InfoKind>震度速報</InfoKind>')
        expect(item.state).to eq 'closed'

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end

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
  end
end
