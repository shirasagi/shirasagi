require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example, es: true do
  let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }

  before do
    @save = {}
    ENV.each do |key, value|
      @save[key.dup] = value.dup
    end

    # gws:es:ingest:init
    ::Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    ::Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    ::Gws::Elasticsearch.create_index(site: site)
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
