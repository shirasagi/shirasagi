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
    let(:up1) { Fs::UploadedFile.create_from_file(content, basename: unique_id, content_type: 'application/octet-stream') }
    let!(:file1) { create(:gws_share_file, cur_site: site, cur_user: user, in_file: up1) }
    let(:up2) { Fs::UploadedFile.create_from_file(content, basename: unique_id, content_type: 'application/octet-stream') }
    let!(:file2) { create(:gws_share_file, cur_site: site, cur_user: user, in_file: up2) }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_file) do
      up = Fs::UploadedFile.create_from_file(content, basename: unique_id, content_type: 'application/octet-stream')
      create(:gws_share_file, cur_site: site, cur_user: user, in_file: up, deleted: now)
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_files }.to output(include(file1.name, file2.name)).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 2
        ids = es_docs["hits"]["hits"].map { |es_doc| es_doc["_id"] }
        expect(ids).to include("file-#{file1.id}", "file-#{file2.id}")
      end
    end
  end
end
