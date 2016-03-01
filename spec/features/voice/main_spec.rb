require 'spec_helper'

describe "voice_main", http_server: true do
  http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "voice")

  let(:voice_site) do
    SS::Site.find_or_create_by(name: "VoiceSite", host: "voicehost", domains: "127.0.0.1:33190")
  end

  before do
    # To stabilize spec, voice synthesis job is executed in-place process .
    allow(SS::RakeRunner).to receive(:run_async).and_wrap_original do |_, *args|
      config = { name: "default", model: "job:service", num_workers: 0, poll: %w(default voice_synthesis) }
      config.stringify_keys!
      Job::Service.run config
    end
    # To stabilize spec, bypass open jatalk/lame/sox.
    allow(Voice::Converter).to receive(:convert).and_wrap_original do |_, *args|
      _, _, output = args
      Fs.binwrite(output, IO.binread("#{Rails.root}/spec/fixtures/voice/voice-disabled.wav"))
      true
    end
  end

  describe "#index", open_jtalk: true do
    context "when valid site is given" do
      before :all do
        @path = "#{rand(0x100000000).to_s(36)}.html"
      end

      before do
        http.options real_path: "/test-001.html"
      end

      it "returns 202" do
        url = "http://#{voice_site.domain}/#{@path}"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 202
        expect(response_headers.keys).to include("Retry-After")
        expect(Voice::File.where(url: url).count).to be >= 1

        # wait for a while or wait until status_code turns to 200.
        require 'timeout'
        Timeout.timeout(60) do
          loop do
            visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
            break if status_code == 200
            sleep 1
          end
        end

        # visit again
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 200
        expect(response_headers).to include("Content-Type" => "audio/mpeg")
        expect(response_headers.keys).to_not include("Retry-After")
      end
    end

    context "when invalid site is given" do
      it "returns 404" do
        url = "http://not-exsit-host-#{rand(0x100000000).to_s(36)}/"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when malformed url is given" do
      it "returns 400" do
        url = "http:/xyz/"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 400
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when accessing not existing doc" do
      it "returns 404" do
        url = "http://#{voice_site.domain}/not-exist-doc-#{rand(0x100000000).to_s(36)}.html"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 400" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html", status_code: 400
      end

      it "returns 404" do
        url = "http://#{voice_site.domain}/#{path}?status_code=400"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 404" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html", status_code: 404
      end

      it "returns 404" do
        url = "http://#{voice_site.domain}/#{path}?status_code=404"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server responds 500" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html", status_code: 500
      end

      it "returns 404" do
        url = "http://#{voice_site.domain}/#{path}?status_code=500"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 404
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when voice synthesis request is full" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html"
      end

      it "returns 429" do
        allow(Voice::SynthesisJob).to receive(:call_async).and_raise(Job::SizeLimitExceededError)
        url = "http://#{voice_site.domain}/#{path}"
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 429
        expect(Voice::File.where(url: url).count).to eq 0
      end
    end

    context "when server does not respond last_modified" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html", last_modified: nil
      end

      it "returns 200" do
        url0 = "http://#{voice_site.domain}/#{path}"
        url = "#{url0}?last_modified=nil"
        # request url with query string
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 202
        expect(response_headers.keys).to include("Retry-After")
        # record exists if query string is not given.
        expect(Voice::File.where(url: url0).count).to be >= 1
        # record does not exist if query string is given.
        expect(Voice::File.where(url: url).count).to eq 0

        # wait for a while or wait until status_code turns to 200.
        require 'timeout'
        Timeout.timeout(60) do
          loop do
            visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
            break if status_code == 200
            sleep 1
          end
        end

        # visit again
        visit voice_path(URI.escape(url, /[^0-9a-zA-Z]/n))
        expect(status_code).to eq 200
        expect(response_headers).to include("Content-Type" => "audio/mpeg")
        expect(response_headers.keys).to_not include("Retry-After")
      end
    end
  end
end
