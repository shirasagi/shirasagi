require 'spec_helper'

describe "gws_elasticsearch_search_faq", type: :feature, dbscope: :example, js: true, es: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:permissions) do
    %w(
      use_gws_faq
      read_private_gws_faq_posts
      edit_private_gws_faq_posts
      delete_private_gws_faq_posts
    )
  end
  let(:role1) { create(:gws_role_admin) }
  let(:role2) { create(:gws_role, permissions: permissions) }

  let(:user1) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group1.id ], gws_role_ids: [ role1.id ]) }
  let(:user2) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }
  let(:user3) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }

  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  let(:cate1) { create(:gws_faq_category, cur_site: site) }
  let(:cate2) { create(:gws_faq_category, cur_site: site) }
  let(:cate3) { create(:gws_faq_category, cur_site: site) }

  let(:item1) do
    create(
      :gws_faq_topic, state: "public", category_ids: [ cate1.id, cate2.id ],
      readable_setting_range: "select", readable_member_ids: [user1.id], readable_group_ids: [])
  end
  let(:item2) do
    create(
      :gws_faq_topic, state: "public", category_ids: [ cate2.id, cate3.id ],
      readable_setting_range: "select", readable_member_ids: [user2.id], readable_group_ids: [])
  end
  let(:item3) do
    create(
      :gws_faq_topic, state: "public", category_ids: [ cate3.id, cate1.id ],
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group1.id])
  end
  let(:item4) do
    create(
      :gws_faq_topic, state: "public", category_ids: [ cate1.id, cate2.id ],
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group2.id])
  end
  let(:item5) do
    create(
      :gws_faq_topic, state: "closed", category_ids: [ cate2.id, cate3.id ],
      readable_setting_range: "select", readable_member_ids: [user1.id], readable_group_ids: [])
  end
  let(:item6) do
    create(
      :gws_faq_topic, state: "closed", category_ids: [ cate3.id, cate1.id ],
      readable_setting_range: "select", readable_member_ids: [user2.id], readable_group_ids: [])
  end
  let(:item7) do
    create(
      :gws_faq_topic, state: "closed", category_ids: [ cate1.id, cate2.id ],
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group1.id])
  end
  let(:item8) do
    create(
      :gws_faq_topic, state: "closed", category_ids: [ cate2.id, cate3.id ],
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group2.id])
  end
  let(:item9) do
    create(
      :gws_faq_topic, state: "closed", category_ids: [ cate3.id, cate1.id ],
      readable_setting_range: "select", readable_member_ids: [user3.id], group_ids: [group2.id])
  end
  let(:item10) do
    create(
      :gws_faq_topic, state: "closed", category_ids: [ cate1.id, cate2.id ],
      readable_setting_range: "select", readable_member_ids: [user3.id], user_ids: [user2.id])
  end
  let(:item11) do
    # back number
    create(
      :gws_faq_topic, state: "public", category_ids: [ cate2.id, cate3.id ],
      readable_setting_range: "select", readable_member_ids: [user2.id], readable_group_ids: [],
      close_date: now - 1.day)
  end

  before do
    @save_max_items_per_page = Gws::Elasticsearch.max_items_per_page
    Gws::Elasticsearch.max_items_per_page = 50

    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.elasticsearch_hosts = SS::EsSupport.es_url
    site.save

    # gws:es:ingest:init
    ::Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    ::Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    ::Gws::Elasticsearch.create_index(site: site)

    perform_enqueued_jobs do
      expectation = expect do
        item1
        item2
        item3
        item4
        item5
        item6
        item7
        item8
        item9
        item10
        item11
      end
      expectation.to change { performed_jobs.size }.by(11)
    end

    # wait for indexing
    ::Gws::Elasticsearch.refresh_index(site: site)
  end

  after do
    Gws::Elasticsearch.max_items_per_page = @save_max_items_per_page
  end

  context "user1" do
    context "search all" do
      it do
        login_user user1, to: gws_elasticsearch_search_search_path(site: site.id, type: 'faq')
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item', count: 11)
        within ".list-item[data-id='gws_faq_posts-post-#{item1.id}']" do
          expect(page).to have_css(".title", text: item1.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item2.id}']" do
          expect(page).to have_css(".title", text: item2.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate3.id}']", text: cate3.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item3.id}']" do
          expect(page).to have_css(".title", text: item3.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate3.id}']", text: cate3.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item4.id}']" do
          expect(page).to have_css(".title", text: item4.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item5.id}']" do
          expect(page).to have_css(".title", text: item5.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate3.id}']", text: cate3.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item6.id}']" do
          expect(page).to have_css(".title", text: item6.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate3.id}']", text: cate3.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item7.id}']" do
          expect(page).to have_css(".title", text: item7.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item8.id}']" do
          expect(page).to have_css(".title", text: item8.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate3.id}']", text: cate3.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item9.id}']" do
          expect(page).to have_css(".title", text: item9.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate3.id}']", text: cate3.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item10.id}']" do
          expect(page).to have_css(".title", text: item10.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate1.id}']", text: cate1.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
        end
        within ".list-item[data-id='gws_faq_posts-post-#{item11.id}']" do
          expect(page).to have_css(".title", text: item11.name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate2.id}']", text: cate2.trailing_name)
          expect(page).to have_css(".gws-category-label[data-id='#{cate3.id}']", text: cate3.trailing_name)
        end
      end
    end
  end
end
