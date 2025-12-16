require 'spec_helper'

describe Gws::Elasticsearch::Indexer::CircularPostJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }

  describe '.convert_to_doc' do
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:post_user) { create :gws_user, organization: site, group_ids: [ group1.id ] }
    let!(:member_user1) { create :gws_user, organization: site, group_ids: [ group2.id ] }
    let!(:member_user2) { create :gws_user, organization: site, group_ids: [ group3.id ] }
    let!(:member_user3) { create :gws_user, organization: site, group_ids: [ group3.id ] }
    let!(:cate) { create :gws_circular_category, cur_site: site }
    let!(:post) do
      create(
        :gws_circular_post, :due_date, cur_site: site, cur_user: post_user, state: "public",
        category_ids: [ cate.id ], member_ids: [ member_user1.id, member_user2.id ], user_ids: [ post_user.id ]
      )
    end

    context "with post" do
      it do
        id, doc = Gws::Elasticsearch::Indexer::CircularPostJob.convert_to_doc(site, post, post)
        unhandled_keys = [] if Rails.env.test?
        Gws::Elasticsearch.mappings_keys.each do |key|
          unless doc.key?(key.to_sym)
            unhandled_keys << key
          end
        end

        expect(id).to eq "gws_circular_posts-post-#{post.id}"
        expect(doc[:collection_name]).to eq post.collection_name.to_sym
        expect(doc[:url]).to eq "/.g#{site.id}/circular/-/posts/#{post.id}#post-#{post.id}"
        expect(doc[:name]).to eq post.name
        expect(doc[:text]).to eq post.text
        expect(doc[:categories]).to eq [ cate.name ]
        expect(doc[:user_name]).to eq post_user.long_name
        expect(doc[:release_date]).to be_blank
        expect(doc[:close_date]).to be_blank
        expect(doc[:released]).to be_blank
        expect(doc[:state]).to eq post.state
        expect(doc[:user_ids]).to eq post.user_ids
        expect(doc[:user_ids]).to eq [ post_user.id ]
        expect(doc[:group_ids]).to be_blank
        expect(doc[:custom_group_ids]).to be_blank
        expect(doc[:member_ids]).to eq [ member_user1.id, member_user2.id ]
        expect(doc[:member_group_ids]).to be_blank
        expect(doc[:member_custom_group_ids]).to be_blank
        expect(doc[:updated]).to eq post.updated.iso8601
        expect(doc[:created]).to eq post.created.iso8601

        omittable_fields = %i[
          id mode release_date close_date released groups group_names
          readable_member_ids readable_group_ids readable_custom_group_ids
          text_index data file site_id attachment]
        unhandled_keys.reject! { |key| omittable_fields.include?(key.to_sym) }
        expect(unhandled_keys).to be_blank
      end
    end

    context "with comment having 'all' as browsing_authority" do
      let!(:comment) do
        # 親 post には存在しないユーザー member_user3 を user_ids に追加
        create(
          :gws_circular_comment, cur_site: site, cur_user: member_user1, post: post, name: "Re: #{post.name}",
          browsing_authority: "all", user_ids: [ member_user1.id, member_user3.id ], group_ids: member_user1.group_ids
        )
      end

      it do
        id, doc = Gws::Elasticsearch::Indexer::CircularCommentJob.convert_to_doc(site, post, comment)
        unhandled_keys = [] if Rails.env.test?
        Gws::Elasticsearch.mappings_keys.each do |key|
          unless doc.key?(key.to_sym)
            unhandled_keys << key
          end
        end

        expect(id).to eq "gws_circular_posts-post-#{comment.id}"
        expect(doc[:collection_name]).to eq post.collection_name.to_sym
        expect(doc[:url]).to eq "/.g#{site.id}/circular/-/posts/#{post.id}#post-#{comment.id}"
        expect(doc[:name]).to eq comment.name
        expect(doc[:text]).to eq comment.text
        expect(doc[:categories]).to eq [ cate.name ]
        expect(doc[:user_name]).to eq member_user1.long_name
        expect(doc[:release_date]).to be_blank
        expect(doc[:close_date]).to be_blank
        expect(doc[:released]).to be_blank
        expect(doc[:state]).to eq post.state
        expect(doc[:user_ids]).to eq comment.user_ids
        expect(doc[:group_ids]).to eq comment.group_ids
        expect(doc[:custom_group_ids]).to be_blank
        expect(doc[:member_ids]).to eq [ member_user1.id, member_user2.id ]
        expect(doc[:member_group_ids]).to be_blank
        expect(doc[:member_custom_group_ids]).to be_blank
        expect(doc[:updated]).to eq comment.updated.iso8601
        expect(doc[:created]).to eq comment.created.iso8601

        omittable_fields = %i[
          id mode release_date close_date released groups group_names
          readable_member_ids readable_group_ids readable_custom_group_ids
          text_index data file site_id attachment]
        unhandled_keys.reject! { |key| omittable_fields.include?(key.to_sym) }
        expect(unhandled_keys).to be_blank
      end
    end

    context "with comment having 'author_or_commenter' as browsing_authority" do
      let!(:comment) do
        # 親 post には存在しないユーザー member_user3 を user_ids に追加
        create(
          :gws_circular_comment, cur_site: site, cur_user: member_user1, post: post, name: "Re: #{post.name}",
          browsing_authority: "author_or_commenter",
          user_ids: [ member_user1.id, member_user3.id ], group_ids: member_user1.group_ids
        )
      end

      it do
        id, doc = Gws::Elasticsearch::Indexer::CircularCommentJob.convert_to_doc(site, post, comment)
        unhandled_keys = [] if Rails.env.test?
        Gws::Elasticsearch.mappings_keys.each do |key|
          unless doc.key?(key.to_sym)
            unhandled_keys << key
          end
        end

        expect(id).to eq "gws_circular_posts-post-#{comment.id}"
        expect(doc[:collection_name]).to eq post.collection_name.to_sym
        expect(doc[:url]).to eq "/.g#{site.id}/circular/-/posts/#{post.id}#post-#{comment.id}"
        expect(doc[:name]).to eq comment.name
        expect(doc[:text]).to eq comment.text
        expect(doc[:categories]).to eq [ cate.name ]
        expect(doc[:user_name]).to eq member_user1.long_name
        expect(doc[:release_date]).to be_blank
        expect(doc[:close_date]).to be_blank
        expect(doc[:released]).to be_blank
        expect(doc[:state]).to eq post.state
        expect(doc[:user_ids]).to eq comment.user_ids
        expect(doc[:group_ids]).to eq comment.group_ids
        expect(doc[:custom_group_ids]).to be_blank
        expect(doc[:member_ids]).to eq [ member_user1.id, member_user2.id ]
        expect(doc[:member_group_ids]).to be_blank
        expect(doc[:member_custom_group_ids]).to be_blank
        expect(doc[:updated]).to eq comment.updated.iso8601
        expect(doc[:created]).to eq comment.created.iso8601

        omittable_fields = %i[
          id mode release_date close_date released groups group_names
          readable_member_ids readable_group_ids readable_custom_group_ids
          text_index data file site_id attachment]
        unhandled_keys.reject! { |key| omittable_fields.include?(key.to_sym) }
        expect(unhandled_keys).to be_blank
      end
    end
  end

  describe '.callback' do
    let(:user) { gws_user }
    let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
    let(:file) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }
    let(:category) { create(:gws_circular_category, cur_site: site) }

    before do
      # enable elastic search
      site.menu_elasticsearch_state = 'show'
      site.save!

      # gws:es:ingest:init
      Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      Gws::Elasticsearch.create_index(site: site)
    end

    context 'when model was created' do
      it do
        post = nil
        perform_enqueued_jobs do
          expectation = expect do
            post = create(
              :gws_circular_post, :member_ids, :due_date,
              cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id]
            )
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.all.to_a.tap do |logs|
          logs[0].tap do |log|
            expect(log.class_name).to eq "Gws::Elasticsearch::Indexer::CircularPostJob"
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
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
        end
      end
    end

    context 'when model was updated' do
      let!(:post) do
        create(
          :gws_circular_post, :member_ids, :due_date,
          cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id]
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.text = unique_id
            post.file_ids = []
            post.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          # confirm that file was removed from post
          expect(es_docs["hits"]["hits"].length).to eq 1
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_circular_posts-post-#{post.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/circular/-/posts/#{post.id}#post-#{post.id}"
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:post) do
        create(
          :gws_circular_post, :member_ids, :due_date,
          cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id]
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
        end
      end
    end

    context 'when model was soft deleted' do
      let!(:post) do
        create(
          :gws_circular_post, :member_ids, :due_date,
          cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id]
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.deleted = Time.zone.now
            post.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
        end
      end
    end
  end
end
