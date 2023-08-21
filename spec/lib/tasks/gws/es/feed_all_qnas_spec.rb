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

  describe ".feed_all_qnas" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let(:category) { create(:gws_qna_category, cur_site: site, cur_user: user) }
    let!(:file) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:topic) do
      create(:gws_qna_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
    end
    let!(:post) { create(:gws_qna_post, cur_site: site, cur_user: user, topic: topic, parent: topic) }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_topic) do
      create(:gws_qna_topic, cur_site: site, cur_user: user, category_ids: [category.id], deleted: now)
    end
    let!(:deleted_post) do
      create(:gws_qna_post, cur_site: site, cur_user: user, topic: deleted_topic, parent: deleted_topic, deleted: now)
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_qnas }.to output(include("-- #{post.name}\n")).to_stdout

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 3
        es_docs["hits"]["hits"][0].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_qna_posts-post-#{topic.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{topic.id}"
        end
        es_docs["hits"]["hits"][1].tap do |es_doc|
          expect(es_doc["_id"]).to eq "file-#{file.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#file-#{file.id}"
        end
        es_docs["hits"]["hits"][2].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_qna_posts-post-#{post.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{post.id}"
        end
      end
    end
  end
end
