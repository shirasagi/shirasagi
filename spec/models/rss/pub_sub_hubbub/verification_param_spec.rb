require 'spec_helper'

describe Rss::PubSubHubbub::VerificationParam, dbscope: :example do
  describe "mode is invalid" do
    subject { build(:rss_pub_sub_hubbub_verification_param, mode: 'invalid_mode') }
    it do
      expect(subject.valid?).to be_falsey
    end
  end

  describe "topic is blank" do
    context 'mode is subscribe' do
      subject { build(:rss_pub_sub_hubbub_verification_param, mode: 'subscribe', topic: '') }
      it do
        expect(subject.valid?).to be_falsey
      end
    end
    context 'mode is unsubscribe' do
      subject { build(:rss_pub_sub_hubbub_verification_param, mode: 'unsubscribe', topic: '') }
      it do
        expect(subject.valid?).to be_falsey
      end
    end
  end

  describe "topic is not subscription target" do
    let(:node) { create(:rss_node_weather_xml, topic_urls: ['http://example.jp/topic1/rss.xml']) }
    subject do
      build(
        :rss_pub_sub_hubbub_verification_param,
        cur_node: node,
        mode: 'subscribe',
        topic: 'http://www.web-tips.co.jp/docs/rss.xml')
    end
    it do
      expect(subject.valid?).to be_falsey
    end
  end

  describe "challenge is blank" do
    context 'mode is subscribe' do
      subject { build(:rss_pub_sub_hubbub_verification_param, mode: 'subscribe', challenge: '') }
      it do
        expect(subject.valid?).to be_falsey
      end
    end
    context 'mode is unsubscribe' do
      subject { build(:rss_pub_sub_hubbub_verification_param, mode: 'unsubscribe', challenge: '') }
      it do
        expect(subject.valid?).to be_truthy
      end
    end
  end
end
