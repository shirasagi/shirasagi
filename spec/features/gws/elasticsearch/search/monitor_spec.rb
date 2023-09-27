require 'spec_helper'

describe "gws_elasticsearch_search_monitor", type: :feature, dbscope: :example, js: true, es: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:index_path) { gws_elasticsearch_search_search_path(site: site.id, type: 'monitor') }

  let(:permissions) do
    %w(
      use_gws_monitor
      read_private_gws_monitor_posts
      edit_private_gws_monitor_posts
      delete_private_gws_monitor_posts
    )
  end
  let(:role1) { create(:gws_role_admin) }
  let(:role2) { create(:gws_role, permissions: permissions) }

  let(:user1) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group1.id ], gws_role_ids: [ role1.id ]) }
  let(:user2) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }
  let(:user3) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }

  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  let(:item1) { create(:gws_monitor_topic, attend_group_ids: [group1.id], state: 'public') }
  let(:item2) { create(:gws_monitor_topic, attend_group_ids: [group2.id], state: 'public') }
  let(:item3) { create(:gws_monitor_topic, attend_group_ids: [group1.id], state: 'closed') }
  let(:item4) { create(:gws_monitor_topic, attend_group_ids: [group2.id], state: 'closed') }
  let(:item5) { create(:gws_monitor_topic, attend_group_ids: [group1.id], state: 'closed', group_ids: [group2.id]) }
  let(:item6) { create(:gws_monitor_topic, attend_group_ids: [group1.id], state: 'closed', user_ids: [user2.id]) }

  before do
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
  end

  context "user1" do
    before { login_user(user1) }

    it do
      perform_enqueued_jobs do
        expectation = expect do
          item1
          item2
          item3
          item4
          item5
          item6
        end
        expectation.to change { performed_jobs.size }.by(6)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      visit index_path
      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item .title', text: item1.name)
      expect(page).to have_css('.list-item .title', text: item2.name)
      expect(page).to have_css('.list-item .title', text: item3.name)
      expect(page).to have_css('.list-item .title', text: item4.name)
      expect(page).to have_css('.list-item .title', text: item5.name)
      expect(page).to have_css('.list-item .title', text: item6.name)

      within '.index form' do
        fill_in 's[keyword]', with: item1.name
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item .title', text: item1.name)
      expect(page).to have_no_css('.list-item .title', text: item2.name)
      expect(page).to have_no_css('.list-item .title', text: item3.name)
      expect(page).to have_no_css('.list-item .title', text: item4.name)
      expect(page).to have_no_css('.list-item .title', text: item5.name)
      expect(page).to have_no_css('.list-item .title', text: item6.name)
    end
  end

  context "user2" do
    before { login_user(user2) }

    it do
      perform_enqueued_jobs do
        expectation = expect do
          item1
          item2
          item3
          item4
          item5
          item6
        end
        expectation.to change { performed_jobs.size }.by(6)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      visit index_path
      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_no_css('.list-item .title', text: item1.name)
      expect(page).to have_css('.list-item .title', text: item2.name)
      expect(page).to have_no_css('.list-item .title', text: item3.name)
      expect(page).to have_no_css('.list-item .title', text: item4.name)
      expect(page).to have_css('.list-item .title', text: item5.name)
      expect(page).to have_css('.list-item .title', text: item6.name)

      within '.index form' do
        fill_in 's[keyword]', with: item1.name
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_no_css('.list-item .title', text: item1.name)
      expect(page).to have_no_css('.list-item .title', text: item2.name)
      expect(page).to have_no_css('.list-item .title', text: item3.name)
      expect(page).to have_no_css('.list-item .title', text: item4.name)
      expect(page).to have_no_css('.list-item .title', text: item5.name)
      expect(page).to have_no_css('.list-item .title', text: item6.name)
    end
  end
end
