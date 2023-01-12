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

  describe ".feed_all_workflows" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:file) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:workflow) { create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [file.id]) }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_workflow) { create(:gws_workflow_file, cur_site: site, cur_user: user, deleted: now) }

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_workflows }.to output(include("- #{workflow.name}\n")).to_stdout

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 2
        es_docs["hits"]["hits"][0].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_workflow_files-workflow-#{workflow.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}"
        end
        es_docs["hits"]["hits"][1].tap do |es_doc|
          expect(es_doc["_id"]).to eq "file-#{file.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}#file-#{file.id}"
        end
      end
    end
  end
end
