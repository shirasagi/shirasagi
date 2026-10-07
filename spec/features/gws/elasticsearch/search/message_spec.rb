require 'spec_helper'

describe "gws_elasticsearch_search_faq", type: :feature, dbscope: :example, js: true, es: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:permissions) do
    %w(
      edit_private_gws_memo_messages
    )
  end
  let(:role1) { create(:gws_role_admin) }
  let(:role2) { create(:gws_role, permissions: permissions) }

  let(:user1) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group1.id ], gws_role_ids: [ role1.id ]) }
  let(:user2) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }
  let(:user3) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }

  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  let(:item1) do
    create :gws_memo_message, cur_site: site, user: user2, in_to_members: [user1.id.to_s]
  end
  let(:item2) do
    create :gws_memo_message, :with_draft, cur_site: site, user: user3, in_to_members: [user1.id.to_s]
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
      end
      expectation.to change { performed_jobs.size }.by(1)
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
        login_user user1, to: gws_elasticsearch_search_search_path(site: site.id, type: 'memo')
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

  context "user2" do
    context "search all" do
      it do
        login_user user2, to: gws_elasticsearch_search_search_path(site: site.id, type: 'memo')
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

  context "user3" do
    context "search all" do
      it do
        login_user user3, to: gws_elasticsearch_search_search_path(site: site.id, type: 'memo')
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.index', text: I18n.t("gws/elasticsearch.format.search_results_count", count: 0))
      end
    end
  end
end
