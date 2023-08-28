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
    let!(:form) { create(:gws_workflow_form, cur_site: site, cur_user: user) }
    let!(:column) { create(:gws_column_file_upload, cur_site: site, cur_form: form) }
    let!(:item) do
      create(:gws_workflow_file, cur_site: site, cur_user: user, form: form, column_values: [column.serialize_value([file.id])])
    end

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_workflow) { create(:gws_workflow_file, cur_site: site, cur_user: user, deleted: now) }

    before do
      ENV['site'] = site.name
    end

    it do
      expectation = expect { described_class.feed_all_workflows }
      expectation.to output(include("- #{item.name}\n")).to_stdout
      expectation.to output(include("- #{form.name}\n")).to_stdout

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 3
        es_docs["hits"]["hits"][0].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_workflow_files-workflow-#{item.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/workflow/files/all/#{item.id}"
        end
        es_docs["hits"]["hits"][1].tap do |es_doc|
          expect(es_doc["_id"]).to eq "file-#{file.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/workflow/files/all/#{item.id}#file-#{file.id}"
        end
        es_docs["hits"]["hits"][2].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_workflow_forms-workflow-#{form.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/workflow/forms/#{form.id}"
        end
      end
    end
  end
end
