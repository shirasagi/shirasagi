require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example, es: true do
  let!(:site) { create :gws_group }

  before do
    @save = {}
    ENV.each do |key, value|
      @save[key.dup] = value.dup
    end
  end

  after do
    ENV.clear
    @save.each do |key, value|
      ENV[key] = value
    end
  end

  describe ".ping" do
    context "when unknown site is given" do
      before { ENV['site'] = unique_id }

      it do
        expect { described_class.ping }.to output(include("Site not found:")).to_stdout
      end
    end

    context "when elasticsearch menu is hidden" do
      let!(:site) { create :gws_group, menu_elasticsearch_state: "hide" }

      before { ENV['site'] = site.name }

      it do
        expect { described_class.ping }.to output(include("elasticsearch was not enabled\n")).to_stdout
      end
    end

    context "when elasticsearch is configured" do
      let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: "http://#{unique_domain}" }

      before do
        ENV['site'] = site.name
      end

      it do
        expect { described_class.ping }.to output(include("true\n")).to_stdout

        expect(es_requests.length).to eq 1
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'head'
          expect(request['uri']['path']).to end_with("/")
        end
      end
    end
  end
end
