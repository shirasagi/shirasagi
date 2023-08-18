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

  describe ".feed_all_circulars" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let(:category) { create(:gws_circular_category, cur_site: site, cur_user: user) }
    let!(:file) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:post) do
      create(
        :gws_circular_post, :member_ids, :due_date,
        cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id]
      )
    end
    let!(:comment) { create(:gws_circular_comment, cur_site: site, cur_user: user, post: post) }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_post) do
      create(
        :gws_circular_post, :member_ids, :due_date,
        cur_site: site, cur_user: user, category_ids: [category.id], deleted: now
      )
    end
    let!(:deleted_comment) do
      create(:gws_circular_comment, cur_site: site, cur_user: user, post: post, deleted: now)
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_circulars }.to output(include("-- #{comment.name}\n")).to_stdout

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 3
        es_docs["hits"]["hits"][0].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_circular_posts-post-#{post.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/circular/-/posts/#{post.id}#post-#{post.id}"
        end
        es_docs["hits"]["hits"][1].tap do |es_doc|
          expect(es_doc["_id"]).to eq "file-#{file.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/circular/-/posts/#{post.id}#file-#{file.id}"
        end
        es_docs["hits"]["hits"][2].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_circular_posts-post-#{comment.id}"
          source = es_doc["_source"]
          expect(source['url']).to eq "/.g#{site.id}/circular/-/posts/#{post.id}#post-#{comment.id}"
        end
      end
    end
  end
end
