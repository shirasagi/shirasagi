require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  before { login_gws_user }

  context "readables" do
    let!(:index_path) { gws_schedule_todo_readables_path site, "-" }
    let!(:categories_path) { gws_schedule_todo_categories_path site }

    let!(:category1) { create(:gws_schedule_todo_category, cur_site: site, in_basename: unique_id) }
    let!(:category2) { create(:gws_schedule_todo_category, cur_site: site, in_basename: unique_id, in_parent_id: category1.id) }
    let!(:category_root_path) { gws_schedule_todo_readables_path site, category1.id }

    let!(:item1) { create :gws_schedule_todo, cur_site: site, cur_user: user, category_ids: [category1.id] }
    let!(:item2) { create :gws_schedule_todo, cur_site: site, cur_user: user, category_ids: [category2.id] }

    it "#index" do
      visit index_path

      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_css(".categories a[href=\"#{category_root_path}\"]", text: category1.name)

        expect(page).to have_link item2.name
        expect(page).to have_css(".categories a[href=\"#{category_root_path}\"]", text: category2.name)
      end

      # destroy category1
      visit categories_path
      find(".list-item input[type=\"checkbox\"][value=\"#{category1.id}\"]").set(true)
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      visit index_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_css(".categories a[href=\"#{index_path}\"]", text: category2.name)
      end

      # destroy category2
      visit categories_path
      find(".list-item input[type=\"checkbox\"][value=\"#{category2.id}\"]").set(true)
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      visit index_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_css(".categories a")
      end
    end
  end

  context "manageables" do
    let!(:user2) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }

    let!(:index_path) { gws_schedule_todo_manageables_path site, "-" }
    let!(:categories_path) { gws_schedule_todo_categories_path site }

    let!(:category1) { create(:gws_schedule_todo_category, cur_site: site, in_basename: unique_id) }
    let!(:category2) { create(:gws_schedule_todo_category, cur_site: site, in_basename: unique_id, in_parent_id: category1.id) }
    let!(:category_root_path) { gws_schedule_todo_manageables_path site, category1.id }

    let!(:item1) do
      create :gws_schedule_todo, cur_site: site, cur_user: user, category_ids: [category1.id],
        member_ids: [user2.id], user_ids: [user2.id]
    end
    let!(:item2) do
      create :gws_schedule_todo, cur_site: site, cur_user: user, category_ids: [category2.id],
        member_ids: [user2.id], user_ids: [user2.id]
    end

    it "#index" do
      visit index_path

      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_css(".categories a[href=\"#{category_root_path}\"]", text: category1.name)

        expect(page).to have_link item2.name
        expect(page).to have_css(".categories a[href=\"#{category_root_path}\"]", text: category2.name)
      end

      # destroy category1
      visit categories_path
      find(".list-item input[type=\"checkbox\"][value=\"#{category1.id}\"]").set(true)
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      visit index_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_css(".categories a[href=\"#{index_path}\"]", text: category2.name)
      end

      # destroy category2
      visit categories_path
      find(".list-item input[type=\"checkbox\"][value=\"#{category2.id}\"]").set(true)
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      visit index_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_css(".categories a")
      end
    end
  end

  context "trashes" do
    let!(:index_path) { gws_schedule_todo_readables_path site, "-" }
    let!(:trashes_path) { gws_schedule_todo_trashes_path site, "-" }
    let!(:categories_path) { gws_schedule_todo_categories_path site }

    let!(:category1) { create(:gws_schedule_todo_category, cur_site: site, in_basename: unique_id) }
    let!(:category2) { create(:gws_schedule_todo_category, cur_site: site, in_basename: unique_id, in_parent_id: category1.id) }
    let!(:category_root_path) { gws_schedule_todo_readables_path site, category1.id }

    let!(:item1) { create :gws_schedule_todo, cur_site: site, cur_user: user, category_ids: [category1.id] }
    let!(:item2) { create :gws_schedule_todo, cur_site: site, cur_user: user, category_ids: [category2.id] }

    it "#index" do
      visit index_path

      # destroy items
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      visit trashes_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_css(".categories a", text: category1.name)

        expect(page).to have_link item2.name
        expect(page).to have_css(".categories a", text: category2.name)
      end

      # destroy category1
      visit categories_path
      find(".list-item input[type=\"checkbox\"][value=\"#{category1.id}\"]").set(true)
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      visit trashes_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_css(".categories a", text: category2.name)
      end

      # destroy category2
      visit categories_path
      find(".list-item input[type=\"checkbox\"][value=\"#{category2.id}\"]").set(true)
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      visit trashes_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_css(".categories a")
      end
    end
  end
end
