require 'spec_helper'

describe "voice_main", type: :feature, dbscope: :example, open_jtalk: true do
  let(:voice_site) do
    SS::Site.find_or_create_by(name: "VoiceSite", host: "voicehost", domains: unique_domain)
  end
  let(:ua) { 'shirasagi rspec' }

  before do
    WebMock.reset!

    # To stabilize spec, bypass open jatalk/lame/sox.
    allow(Voice::Converter).to receive(:convert).and_wrap_original do |_, *args|
      _, _, output = args
      Fs.binwrite(output, IO.binread("#{Rails.root}/spec/fixtures/voice/voice-disabled.wav"))
      true
    end

    # explicitly set user-agent to pass bot detection
    page.driver.header('User-Agent', ua)
  end
  after { WebMock.reset! }

  describe "#index" do
    context "when valid site is given" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }
      let(:html_path) { "#{Rails.root}/spec/fixtures/voice/test-001.html" }

      before do
        stub_request(:get, url).
          to_return(status: 200, body: File.binread(html_path), headers: { "Last-Modified" => Time.zone.now.httpdate })
      end

      around do |example|
        perform_enqueued_jobs { example.run }
      end

      it "returns 202, and then returns 200" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 202
        expect(response_headers.keys).to include("retry-after")
        expect(Voice::File.where(url: url).count).to be >= 1

        # visit again
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 200
        expect(response_headers).to include("Content-Type" => "audio/mpeg")
        expect(response_headers.keys).to_not include("retry-after")
      end
    end

    context "when invalid site is given" do
      let(:url) { "http://not-exsit-host-#{unique_id}/" }

      it "returns 404" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when malformed url is given" do
      let(:url) { "http:/xyz/" }

      it "returns 400" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 400
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when accessing not existing doc" do
      let(:url) { "http://#{voice_site.domain}/not-exist-doc-#{unique_id}.html" }

      it "returns 404" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 400" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }

      before do
        stub_request(:get, url).
          to_return(status: 400, body: "bad request", headers: {})
      end

      it "returns 404" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 404" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }

      before do
        stub_request(:get, url).
          to_return(status: 404, body: "not found", headers: {})
      end

      it "returns 404" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 500" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }

      before do
        stub_request(:get, url).
          to_return(status: 500, body: "internal server error", headers: {})
      end

      it "returns 404" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when voice synthesis request is full" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }
      let(:html_path) { "#{Rails.root}/spec/fixtures/voice/test-001.html" }
      let(:job) { double("Voice::SynthesisJob") }

      before do
        stub_request(:get, url).
          to_return(status: 200, body: File.binread(html_path), headers: { "Last-Modified" => Time.zone.now.httpdate })

        allow(Voice::SynthesisJob).to receive(:new).and_return(job)
        allow(job).to receive(:bind).and_return(job)
        allow(job).to receive(:enqueue).and_raise(Job::SizeLimitExceededError)
      end

      it "returns 429" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 429
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server does not respond last_modified" do
      let(:path) { "#{unique_id}.html" }
      let(:url0) { "http://#{voice_site.domain}/#{path}" }
      let(:url) { "#{url0}?a=b" }
      let(:html_path) { "#{Rails.root}/spec/fixtures/voice/test-001.html" }

      before do
        stub_request(:get, url0).
          to_return(status: 200, body: File.binread(html_path), headers: {})
      end

      around do |example|
        perform_enqueued_jobs { example.run }
      end

      it "returns 200" do
        # request url with query string
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 202
        expect(response_headers.keys).to include("retry-after")
        # record exists if query string is not given.
        expect(Voice::File.where(url: url0).count).to be >= 1
        # record does not exist if query string is given.
        expect(Voice::File.where(url: url).count).to eq 0

        # visit again
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 200
        expect(response_headers).to include("Content-Type" => "audio/mpeg")
        expect(response_headers.keys).to_not include("retry-after")
      end
    end

    context "when user-agent is spider" do
      let(:ua) { "Mozilla/5.0 (compatible; Linespider/1.1; +https://lin.ee/4dwXkTH)" }
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }

      it "returns 404" do
        visit voice_path(Addressable::URI.encode_component(url, '0-9a-zA-Z'))
        expect(status_code).to eq 404
      end
    end
  end
end
