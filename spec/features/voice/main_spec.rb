require 'spec_helper'

describe "voice_main", dbscope: :example, http_server: true do
  http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "voice")

  let(:voice_site) do
    SS::Site.find_or_create_by(name: "VoiceSite", host: "voicehost", domains: "127.0.0.1:33190")
  end

  before do
    # To stabilize spec, bypass open jatalk/lame/sox.
    allow(Voice::Converter).to receive(:convert).and_wrap_original do |_, *args|
      _, _, output = args
      Fs.binwrite(output, IO.binread("#{Rails.root}/spec/fixtures/voice/voice-disabled.wav"))
      true
    end
  end

  describe "#index", open_jtalk: true do
    context "when valid site is given" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }

      before do
        http.options real_path: "/test-001.html"
      end

      around do |example|
        perform_enqueued_jobs { example.run }
      end

      it "returns 202, and then returns 200" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 202
        expect(response_headers.keys).to include("Retry-After")
        expect(Voice::File.where(url: url).count).to be >= 1

        # visit again
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 200
        expect(response_headers).to include("Content-Type" => "audio/mpeg")
        expect(response_headers.keys).to_not include("Retry-After")
      end
    end

    context "when invalid site is given" do
      let(:url) { "http://not-exsit-host-#{unique_id}/" }

      it "returns 404" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when malformed url is given" do
      let(:url) { "http:/xyz/" }

      it "returns 400" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 400
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when accessing not existing doc" do
      let(:url) { "http://#{voice_site.domain}/not-exist-doc-#{unique_id}.html" }

      it "returns 404" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 400" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}?status_code=400" }

      before do
        http.options real_path: "/test-001.html", status_code: 400
      end

      it "returns 404" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 404" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}?status_code=404" }

      before do
        http.options real_path: "/test-001.html", status_code: 404
      end

      it "returns 404" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 500" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}?status_code=500" }

      before do
        http.options real_path: "/test-001.html", status_code: 500
      end

      it "returns 404" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when voice synthesis request is full" do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://#{voice_site.domain}/#{path}" }
      let(:job) { double("Voice::SynthesisJob") }

      before do
        http.options real_path: "/test-001.html"

        allow(Voice::SynthesisJob).to receive(:new).and_return(job)
        allow(job).to receive(:bind).and_return(job)
        allow(job).to receive(:enqueue).and_raise(Job::SizeLimitExceededError)
      end

      it "returns 429" do
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 429
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server does not respond last_modified" do
      let(:path) { "#{unique_id}.html" }
      let(:url0) { "http://#{voice_site.domain}/#{path}" }
      let(:url) { "#{url0}?last_modified=nil" }

      before do
        http.options real_path: "/test-001.html", last_modified: nil
      end

      around do |example|
        perform_enqueued_jobs { example.run }
      end

      it "returns 200" do
        # request url with query string
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 202
        expect(response_headers.keys).to include("Retry-After")
        # record exists if query string is not given.
        expect(Voice::File.where(url: url0).count).to be >= 1
        # record does not exist if query string is given.
        expect(Voice::File.where(url: url).count).to eq 0

        # visit again
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 200
        expect(response_headers).to include("Content-Type" => "audio/mpeg")
        expect(response_headers.keys).to_not include("Retry-After")
      end
    end
  end
end
