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

  describe ".feed_all_faqs" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let(:category) { create(:gws_faq_category, cur_site: site, cur_user: user) }
    let!(:file1) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:topic1) do
      create(:gws_faq_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file1.id])
    end
    let!(:post1) { create(:gws_faq_post, cur_site: site, cur_user: user, topic: topic1, parent: topic1) }

    let!(:file2) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:topic2) do
      create(:gws_faq_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file2.id])
    end
    let!(:post2) { create(:gws_faq_post, cur_site: site, cur_user: user, topic: topic2, parent: topic2) }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_topic) do
      create(:gws_faq_topic, cur_site: site, cur_user: user, category_ids: [category.id], deleted: now)
    end
    let!(:deleted_post) do
      create(:gws_faq_post, cur_site: site, cur_user: user, topic: topic1, parent: topic1, deleted: now)
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_faqs }.to output(include(post1.name, post2.name)).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 6
        ids = es_docs["hits"]["hits"].map { |es_doc| es_doc["_id"] }
        expect(ids).to include(
          "gws_faq_posts-post-#{topic1.id}", "file-#{file1.id}", "gws_faq_posts-post-#{post1.id}",
          "gws_faq_posts-post-#{topic2.id}", "file-#{file2.id}", "gws_faq_posts-post-#{post2.id}")
      end
    end
  end
end
