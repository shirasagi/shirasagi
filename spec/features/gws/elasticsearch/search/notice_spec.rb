require 'spec_helper'

describe "gws_elasticsearch_search_monitor", type: :feature, dbscope: :example, js: true, es: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:index_path) { gws_elasticsearch_search_search_path(site: site.id, type: 'notice') }

  let(:permissions) do
    %w(
      use_gws_notice
      read_private_gws_notices
      edit_private_gws_notices
      delete_private_gws_notices
    )
  end
  let(:role1) { create(:gws_role_admin) }
  let(:role2) { create(:gws_role, permissions: permissions) }

  let(:user1) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group1.id ], gws_role_ids: [ role1.id ]) }
  let(:user2) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }
  let(:user3) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }

  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  let(:folder1) { create(:gws_notice_folder, cur_site: site) }

  let(:item1) do
    create(
      :gws_notice_post, folder: folder1, state: "public",
      readable_setting_range: "select", readable_member_ids: [user1.id], readable_group_ids: [])
  end
  let(:item2) do
    create(
      :gws_notice_post, folder: folder1, state: "public",
      readable_setting_range: "select", readable_member_ids: [user2.id], readable_group_ids: [])
  end
  let(:item3) do
    create(
      :gws_notice_post, folder: folder1, state: "public",
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group1.id])
  end
  let(:item4) do
    create(
      :gws_notice_post, folder: folder1, state: "public",
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group2.id])
  end
  let(:item5) do
    create(
      :gws_notice_post, folder: folder1, state: "closed",
      readable_setting_range: "select", readable_member_ids: [user1.id], readable_group_ids: [])
  end
  let(:item6) do
    create(
      :gws_notice_post, folder: folder1, state: "closed",
      readable_setting_range: "select", readable_member_ids: [user2.id], readable_group_ids: [])
  end
  let(:item7) do
    create(
      :gws_notice_post, folder: folder1, state: "closed",
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group1.id])
  end
  let(:item8) do
    create(
      :gws_notice_post, folder: folder1, state: "closed",
      readable_setting_range: "select", readable_member_ids: [user3.id], readable_group_ids: [group2.id])
  end
  let(:item9) do
    create(
      :gws_notice_post, folder: folder1, state: "closed",
      readable_setting_range: "select", readable_member_ids: [user3.id], group_ids: [group2.id])
  end
  let(:item10) do
    create(
      :gws_notice_post, folder: folder1, state: "closed",
      readable_setting_range: "select", readable_member_ids: [user3.id], user_ids: [user2.id])
  end

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
      end
      expectation.to change { performed_jobs.size }.by(10)
    end

    # wait for indexing
    ::Gws::Elasticsearch.refresh_index(site: site)
  end

  context "user1" do
    before { login_user(user1) }

    context "search all" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item', count: 10)
        expect(page).to have_css('.list-item .title', text: item1.name)
        expect(page).to have_css('.list-item .title', text: item2.name)
        expect(page).to have_css('.list-item .title', text: item3.name)
        expect(page).to have_css('.list-item .title', text: item4.name)
        expect(page).to have_css('.list-item .title', text: item5.name)
        expect(page).to have_css('.list-item .title', text: item6.name)
        expect(page).to have_css('.list-item .title', text: item7.name)
        expect(page).to have_css('.list-item .title', text: item8.name)
        expect(page).to have_css('.list-item .title', text: item9.name)
        expect(page).to have_css('.list-item .title', text: item10.name)
      end
    end

    context "search with item1's name" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: item1.name
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item', count: 1)
        expect(page).to have_css('.list-item .title', text: item1.name)
        expect(page).to have_no_css('.list-item .title', text: item2.name)
        expect(page).to have_no_css('.list-item .title', text: item3.name)
        expect(page).to have_no_css('.list-item .title', text: item4.name)
        expect(page).to have_no_css('.list-item .title', text: item5.name)
        expect(page).to have_no_css('.list-item .title', text: item6.name)
        expect(page).to have_no_css('.list-item .title', text: item7.name)
        expect(page).to have_no_css('.list-item .title', text: item8.name)
        expect(page).to have_no_css('.list-item .title', text: item9.name)
        expect(page).to have_no_css('.list-item .title', text: item10.name)
      end
    end

    context "transfer to item1" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item1.name)

        click_on item1.name
        expect(current_path).to eq gws_notice_readable_path(site: site, folder_id: "-", category_id: "-", id: item1)
        expect(page).to have_css(".subject", text: item1.name)
      end
    end

    context "transfer to item2" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item2.name)

        click_on item2.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item2)
        expect(page).to have_css("#addon-basic", text: item2.name)
      end
    end

    context "transfer to item3" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item3.name)

        click_on item3.name
        expect(current_path).to eq gws_notice_readable_path(site: site, folder_id: "-", category_id: "-", id: item3)
        expect(page).to have_css(".subject", text: item3.name)
      end
    end

    context "transfer to item4" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item4.name)

        click_on item4.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item4)
        expect(page).to have_css("#addon-basic", text: item4.name)
      end
    end

    context "transfer to item5" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item5.name)

        click_on item5.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item5)
        expect(page).to have_css("#addon-basic", text: item5.name)
      end
    end

    context "transfer to item6" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item6.name)

        click_on item6.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item6)
        expect(page).to have_css("#addon-basic", text: item6.name)
      end
    end

    context "transfer to item7" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item7.name)

        click_on item7.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item7)
        expect(page).to have_css("#addon-basic", text: item7.name)
      end
    end

    context "transfer to item8" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item8.name)

        click_on item8.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item8)
        expect(page).to have_css("#addon-basic", text: item8.name)
      end
    end

    context "transfer to item9" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item9.name)

        click_on item9.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item9)
        expect(page).to have_css("#addon-basic", text: item9.name)
      end
    end

    context "transfer to item10" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item10.name)

        click_on item10.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item10)
        expect(page).to have_css("#addon-basic", text: item10.name)
      end
    end
  end

  context "user2" do
    before { login_user(user2) }

    context "search all" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item', count: 4)
        expect(page).to have_no_css('.list-item .title', text: item1.name)
        expect(page).to have_css('.list-item .title', text: item2.name)
        expect(page).to have_no_css('.list-item .title', text: item3.name)
        expect(page).to have_css('.list-item .title', text: item4.name)
        expect(page).to have_no_css('.list-item .title', text: item5.name)
        expect(page).to have_no_css('.list-item .title', text: item6.name)
        expect(page).to have_no_css('.list-item .title', text: item7.name)
        expect(page).to have_no_css('.list-item .title', text: item8.name)
        expect(page).to have_css('.list-item .title', text: item9.name)
        expect(page).to have_css('.list-item .title', text: item10.name)
      end
    end

    context "search with item1's name" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: item1.name
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item', count: 0)
        expect(page).to have_no_css('.list-item .title', text: item1.name)
        expect(page).to have_no_css('.list-item .title', text: item2.name)
        expect(page).to have_no_css('.list-item .title', text: item3.name)
        expect(page).to have_no_css('.list-item .title', text: item4.name)
        expect(page).to have_no_css('.list-item .title', text: item5.name)
        expect(page).to have_no_css('.list-item .title', text: item6.name)
        expect(page).to have_no_css('.list-item .title', text: item7.name)
        expect(page).to have_no_css('.list-item .title', text: item8.name)
        expect(page).to have_no_css('.list-item .title', text: item9.name)
        expect(page).to have_no_css('.list-item .title', text: item10.name)
      end
    end

    context "transfer to item2" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item2.name)

        click_on item2.name
        expect(current_path).to eq gws_notice_readable_path(site: site, folder_id: "-", category_id: "-", id: item2)
        expect(page).to have_css(".subject", text: item2.name)
      end
    end

    context "transfer to item4" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item4.name)

        click_on item4.name
        expect(current_path).to eq gws_notice_readable_path(site: site, folder_id: "-", category_id: "-", id: item4)
        expect(page).to have_css(".subject", text: item4.name)
      end
    end

    context "transfer to item9" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item9.name)

        click_on item9.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item9)
        expect(page).to have_css("#addon-basic", text: item9.name)
      end
    end

    context "transfer to item10" do
      it do
        visit index_path
        within '.index form' do
          fill_in 's[keyword]', with: "*:*"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css('.list-item .title', text: item10.name)

        click_on item10.name
        expect(current_path).to eq gws_notice_editable_path(site: site, folder_id: "-", category_id: "-", id: item10)
        expect(page).to have_css("#addon-basic", text: item10.name)
      end
    end
  end
end
