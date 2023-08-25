require 'spec_helper'

describe "gws_elasticsearch_search_survey", type: :feature, dbscope: :example, js: true, es: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:index_path) { gws_elasticsearch_search_search_path(site: site.id, type: 'survey') }

  let(:permissions) do
    %w(
      use_gws_survey
      read_private_gws_survey_forms
      edit_private_gws_survey_forms
      delete_private_gws_survey_forms
    )
  end
  let(:role1) { create(:gws_role_admin) }
  let(:role2) { create(:gws_role, permissions: permissions) }

  let(:user1) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group1.id ], gws_role_ids: [ role1.id ]) }
  let(:user2) { create(:gws_user, name: unique_id, email: unique_email, group_ids: [ group2.id ], gws_role_ids: [ role2.id ]) }

  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  let(:cate1) { create(:gws_survey_category, cur_site: site) }
  let(:cate2) { create(:gws_survey_category, cur_site: site) }
  let(:cate3) { create(:gws_survey_category, cur_site: site) }
  let(:cate4) { create(:gws_survey_category, cur_site: site) }
  let(:cate5) { create(:gws_survey_category, cur_site: site) }

  let(:form1) do
    create(:gws_survey_form, cur_site: site, cur_user: user, category_ids: [cate1.id], group_ids: [], user_ids: [])
  end
  let(:form2) do
    create(:gws_survey_form, cur_site: site, cur_user: user, category_ids: [cate2.id], group_ids: [group1.id], user_ids: [])
  end
  let(:form3) do
    create(:gws_survey_form, cur_site: site, cur_user: user, category_ids: [cate3.id], group_ids: [group2.id], user_ids: [])
  end
  let(:form4) do
    create(:gws_survey_form, cur_site: site, cur_user: user, category_ids: [cate4.id], group_ids: [], user_ids: [user1.id])
  end
  let(:form5) do
    create(:gws_survey_form, cur_site: site, cur_user: user, category_ids: [cate5.id], group_ids: [], user_ids: [user2.id])
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
  end

  context "user1" do
    before { login_user(user1) }

    it do
      perform_enqueued_jobs do
        expectation = expect do
          form1
          form2
          form3
          form4
          form5
        end
        expectation.to change { performed_jobs.size }.by(5)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      visit index_path
      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item .title', text: form1.name)
      expect(page).to have_css('.list-item .title', text: form2.name)
      expect(page).to have_css('.list-item .title', text: form3.name)
      expect(page).to have_css('.list-item .title', text: form4.name)
      expect(page).to have_css('.list-item .title', text: form5.name)

      expect(page).to have_css('.gws-category-label', text: cate1.name)
      expect(page).to have_css('.gws-category-label', text: cate2.name)
      expect(page).to have_css('.gws-category-label', text: cate3.name)
      expect(page).to have_css('.gws-category-label', text: cate4.name)
      expect(page).to have_css('.gws-category-label', text: cate5.name)

      within '.index form' do
        fill_in 's[keyword]', with: form1.name
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.list-item .title', text: form1.name)
      expect(page).to have_no_css('.list-item .title', text: form2.name)
      expect(page).to have_no_css('.list-item .title', text: form3.name)
      expect(page).to have_no_css('.list-item .title', text: form4.name)
      expect(page).to have_no_css('.list-item .title', text: form5.name)

      expect(page).to have_css('.gws-category-label', text: cate1.name)
      expect(page).to have_no_css('.gws-category-label', text: cate2.name)
      expect(page).to have_no_css('.gws-category-label', text: cate3.name)
      expect(page).to have_no_css('.gws-category-label', text: cate4.name)
      expect(page).to have_no_css('.gws-category-label', text: cate5.name)
    end
  end

  context "user2" do
    before { login_user(user2) }

    it do
      perform_enqueued_jobs do
        expectation = expect do
          form1
          form2
          form3
          form4
          form5
        end
        expectation.to change { performed_jobs.size }.by(5)
      end

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      visit index_path
      within '.index form' do
        fill_in 's[keyword]', with: "*:*"
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_no_css('.list-item .title', text: form1.name)
      expect(page).to have_no_css('.list-item .title', text: form2.name)
      expect(page).to have_css('.list-item .title', text: form3.name)
      expect(page).to have_no_css('.list-item .title', text: form4.name)
      expect(page).to have_css('.list-item .title', text: form5.name)

      expect(page).to have_no_css('.gws-category-label', text: cate1.name)
      expect(page).to have_no_css('.gws-category-label', text: cate2.name)
      expect(page).to have_css('.gws-category-label', text: cate3.name)
      expect(page).to have_no_css('.gws-category-label', text: cate4.name)
      expect(page).to have_css('.gws-category-label', text: cate5.name)

      within '.index form' do
        fill_in 's[keyword]', with: form1.name
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_no_css('.list-item .title', text: form1.name)
      expect(page).to have_no_css('.list-item .title', text: form2.name)
      expect(page).to have_no_css('.list-item .title', text: form3.name)
      expect(page).to have_no_css('.list-item .title', text: form4.name)
      expect(page).to have_no_css('.list-item .title', text: form5.name)

      expect(page).to have_no_css('.gws-category-label', text: cate1.name)
      expect(page).to have_no_css('.gws-category-label', text: cate2.name)
      expect(page).to have_no_css('.gws-category-label', text: cate3.name)
      expect(page).to have_no_css('.gws-category-label', text: cate4.name)
      expect(page).to have_no_css('.gws-category-label', text: cate5.name)
    end
  end
end
