require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example, es: true do
  before do
    @save = {}
    ENV.each do |key, value|
      @save[key.dup] = value.dup
    end

    # gws:es:ingest:init
    Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    Gws::Elasticsearch.create_index(site: site)
  end

  after do
    ENV.clear
    @save.each do |key, value|
      ENV[key] = value
    end
  end

  describe ".feed_all_workflows2" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:file1) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:form1) { create(:gws_workflow2_form_application, cur_site: site, cur_user: user) }
    let!(:column1) { create(:gws_column_file_upload, cur_site: site, cur_form: form1) }
    let!(:item1) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user, form: form1,
        column_values: [column1.serialize_value([file1.id])]
      )
    end

    let!(:file2) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:form2) { create(:gws_workflow2_form_application, cur_site: site, cur_user: user) }
    let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form2) }
    let!(:item2) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user, form: form2,
        column_values: [column2.serialize_value([file2.id])]
      )
    end

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_form) { create(:gws_workflow2_form_application, cur_site: site, cur_user: user, deleted: now) }
    let!(:deleted_item) { create(:gws_workflow2_file, cur_site: site, cur_user: user, form: deleted_form, deleted: now) }

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_workflows2 }.to output(include(item1.name, item2.name)).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 4
        ids = es_docs["hits"]["hits"].map { |es_doc| es_doc["_id"] }
        expect(ids).to include(
          "gws_workflow2_files-workflow2-#{item1.id}", "file-#{file1.id}",
          "gws_workflow2_files-workflow2-#{item2.id}", "file-#{file2.id}")
      end
    end
  end
end
