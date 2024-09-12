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
    let!(:file1) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:post1) do
      create(
        :gws_circular_post, :member_ids, :due_date,
        cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file1.id]
      )
    end
    let!(:comment1) { create(:gws_circular_comment, cur_site: site, cur_user: user, post: post1) }

    let!(:file2) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:post2) do
      create(
        :gws_circular_post, :member_ids, :due_date,
        cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file2.id]
      )
    end
    let!(:comment2) { create(:gws_circular_comment, cur_site: site, cur_user: user, post: post2) }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_post) do
      create(
        :gws_circular_post, :member_ids, :due_date,
        cur_site: site, cur_user: user, category_ids: [category.id], deleted: now
      )
    end
    let!(:deleted_comment) do
      create(:gws_circular_comment, cur_site: site, cur_user: user, post: post1, deleted: now)
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_circulars }.to output(include(comment1.name, comment2.name)).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 6
        ids = es_docs["hits"]["hits"].map { |es_doc| es_doc["_id"] }
        expect(ids).to include(
          "gws_circular_posts-post-#{post1.id}", "file-#{file1.id}", "gws_circular_posts-post-#{comment1.id}",
          "gws_circular_posts-post-#{post2.id}", "file-#{file2.id}", "gws_circular_posts-post-#{comment2.id}")
      end
    end
  end
end
