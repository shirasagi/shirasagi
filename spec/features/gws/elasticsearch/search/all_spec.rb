require 'spec_helper'

describe "gws_elasticsearch_search_notice", type: :feature, dbscope: :example, js: true, es: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user) { gws_user }
  let!(:user1) { create(:gws_user, group_ids: [ group1.id ], gws_role_ids: user.gws_role_ids) }

  before do
    @save_max_items_per_page = Gws::Elasticsearch.max_items_per_page
    Gws::Elasticsearch.max_items_per_page = 50

    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.elasticsearch_hosts = SS::EsSupport.es_url
    site.save
  end

  after do
    Gws::Elasticsearch.max_items_per_page = @save_max_items_per_page
  end

  context "with gws_notices" do
    let!(:folder1) { create(:gws_notice_folder, cur_site: site) }
    let!(:cate1) { create(:gws_notice_category, cur_site: site) }
    let(:item1) do
      create(
        :gws_notice_post, cur_site: site, folder: folder1, state: "public", category_ids: [ cate1.id ],
        readable_setting_range: "select", readable_member_ids: [ user1.id ], readable_group_ids: [])
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='gws_notices-post-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
        expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
      end
    end
  end

  context "with gws_faq_posts" do
    let!(:cate1) { create(:gws_faq_category, cur_site: site) }
    let(:item1) do
      create(
        :gws_faq_topic, state: "public", category_ids: [ cate1.id ],
        readable_setting_range: "select", readable_member_ids: [ user1.id ], readable_group_ids: [])
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='gws_faq_posts-post-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
        expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
      end
    end
  end

  context "with gws_qna_posts" do
    let!(:cate1) { create(:gws_qna_category, cur_site: site) }
    let(:item1) do
      create(
        :gws_qna_topic, state: "public", category_ids: [ cate1.id ],
        readable_setting_range: "select", readable_member_ids: [ user1.id ], readable_group_ids: [])
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='gws_qna_posts-post-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
        expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
      end
    end
  end

  context "with gws_circular_posts" do
    let!(:cate1) { create(:gws_circular_category, cur_site: site) }
    let(:item1) do
      create(
        :gws_circular_post, state: "public", category_ids: [ cate1.id ],
        due_date: now + 1.day, member_ids: [ user1.id ], member_group_ids: [])
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='gws_circular_posts-post-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
        expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
      end
    end
  end

  context "with gws_monitor_posts" do
    let!(:cate1) { create(:gws_monitor_category, cur_site: site) }
    let(:item1) do
      create(:gws_monitor_topic, category_ids: [ cate1.id ], state: 'public', attend_group_ids: [ group1.id ])
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='gws_monitor_posts-post-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
        expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
      end
    end
  end

  context "with gws_survey_forms" do
    let!(:cate1) { create(:gws_survey_category, cur_site: site) }
    let(:item1) do
      create(:gws_survey_form, cur_site: site, cur_user: user, category_ids: [cate1.id], group_ids: [], user_ids: [])
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='gws_survey_forms-survey-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
        expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
      end
    end
  end

  context "with gws_share_files" do
    let!(:folder1) { create(:gws_share_folder, cur_site: site) }
    let!(:cate1) { create(:gws_share_category, cur_site: site) }
    let(:item1) do
      create(:gws_share_file, cur_site: site, folder: folder1, category_ids: [ cate1.id ])
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='file-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
        expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
      end
    end
  end

  context "with gws_memo_messages" do
    let(:item1) do
      create :gws_memo_message, cur_site: site, user: user, in_to_members: [user.id.to_s]
    end

    it do
      # gws:es:ingest:init
      ::Gws::Elasticsearch.init_ingest(site: site)
      # gws:es:drop
      ::Gws::Elasticsearch.drop_index(site: site) rescue nil
      # gws:es:create_indexes
      ::Gws::Elasticsearch.create_index(site: site)

      perform_enqueued_jobs do
        expectation = expect do
          item1
        end
        expectation.to change { performed_jobs.size }.by(1)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      login_user user, to: gws_elasticsearch_search_search_path(site: site.id, type: 'all')

      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item', count: 1)
      within ".list-item[data-id='gws_memo_messages-message-#{item1.id}']" do
        expect(page).to have_css(".title", text: item1.name)
      end
    end
  end
end
