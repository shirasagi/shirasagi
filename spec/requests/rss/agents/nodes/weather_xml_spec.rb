require 'spec_helper'

describe "Rss::Agents::Nodes::WeatherXmlController", type: :request, dbscope: :example do
  let(:site) { cms_site }

  context "general case" do
    let(:node) { create(:rss_node_weather_xml, cur_site: site) }
    let(:subscriber_path) { "#{node.url}subscriber" }
    let(:challenge) { "1234567890" }

    describe "GET /subscriber" do
      before do
        get(
          "#{subscriber_path}?hub.mode=subscribe&hub.topic=http://example.org/&hub.challenge=#{challenge}",
          {},
          { 'HTTP_HOST' => site.domain })
      end

      it do
        expect(response.status).to eq 200
        expect(response.body).to eq challenge
      end
    end

    describe "POST /subscriber" do
      let(:file) { Rails.root.join(*%w(spec fixtures rss weather-sample.xml)) }
      let(:payload) { File.read(file) }
      let(:content_type) { 'application/xml+rss' }

      before do
        perform_enqueued_jobs do
          post(
            subscriber_path,
            {},
            { 'HTTP_HOST' => site.domain, 'RAW_POST_DATA' => payload, 'CONTENT_TYPE' => content_type })
        end
      end

      it do
        expect(response.status).to eq 200
        expect(response.body).to eq ''
        expect(Rss::WeatherXmlPage.count).to eq 2
      end
    end
  end

  context "specific topic only" do
    let(:node) { create(:rss_node_weather_xml, cur_site: site, topic_urls: 'http://example.org/topic1.xml') }
    let(:subscriber_path) { "#{node.url}subscriber" }
    let(:challenge) { "1234567890" }

    describe "subscribe allowed topis" do
      before do
        get(
          "#{subscriber_path}?hub.mode=subscribe&hub.topic=http://example.org/topic1.xml&hub.challenge=#{challenge}",
          {},
          { 'HTTP_HOST' => site.domain })
      end

      it do
        expect(response.status).to eq 200
        expect(response.body).to eq challenge
      end
    end

    describe "subscribe unallowed topis" do
      before do
        get(
          "#{subscriber_path}?hub.mode=subscribe&hub.topic=http://example.org/topic2.xml&hub.challenge=#{challenge}",
          {},
          { 'HTTP_HOST' => site.domain })
      end

      it do
        expect(response.status).to eq 404
        expect(response.body).to eq ''
      end
    end
  end

  context "hmac digest" do
    let(:secret) { '0987654321' }
    let(:node) { create(:rss_node_weather_xml, cur_site: site, secret: secret) }
    let(:subscriber_path) { "#{node.url}subscriber" }
    let(:challenge) { "1234567890" }
    let(:file) { Rails.root.join(*%w(spec fixtures rss weather-sample.xml)) }
    let(:payload) { File.read(file) }
    let(:content_type) { 'application/xml+rss' }

    before do
      header = {
        'HTTP_HOST' => site.domain,
        'RAW_POST_DATA' => payload,
        'CONTENT_TYPE' => content_type,
        'X-Hub-Signature' => "sha1=#{digest}" }

      perform_enqueued_jobs do
        post(subscriber_path, {}, header)
      end
    end

    describe "valid hmac signature present" do
      let(:digest) { OpenSSL::HMAC.hexdigest('sha1', secret, payload) }

      it do
        expect(response.status).to eq 200
        expect(response.body).to eq ''
        expect(Rss::WeatherXmlPage.count).to eq 2
      end
    end

    describe "invalid hmac signature present" do
      let(:digest) { OpenSSL::HMAC.hexdigest('sha1', secret, 'abcdefg') }

      it do
        expect(response.status).to eq 200
        expect(response.body).to eq ''
        expect(Rss::WeatherXmlPage.count).to eq 0
      end
    end
  end
end
