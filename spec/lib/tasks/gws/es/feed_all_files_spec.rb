require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example, es: true do
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

  describe ".feed_all_files" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let(:content) { tmpfile { |file| file.write('0123456789') } }
    let(:up) { Fs::UploadedFile.create_from_file(content, basename: 'spec', content_type: 'application/octet-stream') }
    let!(:file) { create(:gws_share_file, cur_site: site, cur_user: user, in_file: up) }

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_files }.to output(include("- #{file.name}\n")).to_stdout
    end
  end
end
