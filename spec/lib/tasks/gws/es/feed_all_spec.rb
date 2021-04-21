require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example do
  let(:es_host) { unique_domain }
  let(:es_url) { "http://#{es_host}" }
  let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
  let(:requests) { [] }

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

  describe ".feed_all" do
    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all }.to \
        output(include("gws/memo/message\n", "gws/board/topic and gws/board/post\n", "gws/share/file\n")).to_stdout
    end
  end
end
