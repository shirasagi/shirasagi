require 'spec_helper'

describe Rss::WeatherXml::Action::SendMail, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:rss_weather_xml_action_send_mail) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.not_to be_nil }
    its(:title_mail_text) { is_expected.not_to be_nil }
    its(:upper_mail_text) { is_expected.not_to be_nil }
    its(:loop_mail_text) { is_expected.not_to be_nil }
    its(:lower_mail_text) { is_expected.not_to be_nil }
  end

  describe '#execute' do
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
    let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures rss 70_32-39_11_120615_01shindosokuhou3.xml))) }
    let(:page) { create(:rss_weather_xml_page, xml: xml1) }
    let(:context) { OpenStruct.new(site: site, xmldoc: REXML::Document.new(page.xml)) }
    let(:trigger) { create(:rss_weather_xml_trigger_quake_intensity_flash) }
    subject { create(:rss_weather_xml_action_send_mail) }

    before do
      region_210 = create(:rss_weather_xml_region_210)
      region_211 = create(:rss_weather_xml_region_211)
      region_212 = create(:rss_weather_xml_region_212)
      region_213 = create(:rss_weather_xml_region_213)
      trigger.target_region_ids = [ region_210.id, region_211.id, region_212.id, region_213.id ]
      trigger.save!

      subject.my_anpi_post_id = node_my_anpi_post.id
      subject.anpi_mail_id = node_ezine_member_page.id
      subject.save!

      # sends 10 mails
      id = node_ezine_member_page.id
      10.times do |i|
        create(:cms_member, subscription_ids: [ id ], email_type: %w(text html)[i % 2])
      end
    end

    around do |example|
      Timecop.travel('2011-03-11T05:50:00Z') do
        example.run
      end
    end

    it do
      trigger.verify(page, context) do
        subject.execute(page, context)
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
end
