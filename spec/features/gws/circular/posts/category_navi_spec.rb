require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }
  let!(:cate2) { create(:gws_circular_category) }
  let!(:cate3) { create(:gws_circular_category) }
  let!(:post1) do
    create(
      :gws_circular_post, due_date: now + 1.day, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
      state: "public"
    )
  end
  let!(:post2) do
    create(
      :gws_circular_post, due_date: now + 2.days, category_ids: [ cate2.id ], member_ids: [ gws_user.id, user1.id ],
      state: "public"
    )
  end
  let!(:post3) do
    create(
      :gws_circular_post, due_date: now + 3.days, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
      state: "draft"
    )
  end

  describe "category navi" do
    before { login_gws_user }

    it do
      visit gws_circular_main_path(site: site)
      within ".list-items" do
        expect(page).to have_css(".list-item .title", text: post1.name)
        expect(page).to have_css(".list-item .title", text: post2.name)
        expect(page).to have_no_css(".list-item .title", text: post3.name)
      end

      # choose category: cate1
      within ".gws-category-navi" do
        wait_for_event_fired("ss:dropdownOpened") { click_on I18n.t('gws.category') }
        within ".dropdown-menu.active" do
          click_on cate1.name
        end
      end
      within ".list-items" do
        expect(page).to have_css(".list-item .title", text: post1.name)
        expect(page).to have_no_css(".list-item .title", text: post2.name)
        expect(page).to have_no_css(".list-item .title", text: post3.name)
      end

      # change category: cate1 --> cate2
      within ".gws-category-navi" do
        wait_for_event_fired("ss:dropdownOpened") { click_on cate1.name }
        within ".dropdown-menu.active" do
          click_on cate2.name
        end
      end
      within ".list-items" do
        expect(page).to have_no_css(".list-item .title", text: post1.name)
        expect(page).to have_css(".list-item .title", text: post2.name)
        expect(page).to have_no_css(".list-item .title", text: post3.name)
      end

      # change category: cate2 --> cate3
      within ".gws-category-navi" do
        wait_for_event_fired("ss:dropdownOpened") { click_on cate2.name }
        within ".dropdown-menu.active" do
          click_on cate3.name
        end
      end
      within ".list-items" do
        expect(page).to have_no_css(".list-item .title", text: post1.name)
        expect(page).to have_no_css(".list-item .title", text: post2.name)
        expect(page).to have_no_css(".list-item .title", text: post3.name)
      end

      # clear category
      within ".gws-category-navi" do
        find("a.ml-1").click
      end
      within ".list-items" do
        expect(page).to have_css(".list-item .title", text: post1.name)
        expect(page).to have_css(".list-item .title", text: post2.name)
        expect(page).to have_no_css(".list-item .title", text: post3.name)
      end
    end
  end
end
