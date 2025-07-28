require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }
  let!(:item) do
    create(
      :gws_circular_post, cur_user: gws_user, due_date: now + 1.day, category_ids: [ cate1.id ], member_ids: [ user1.id ],
      state: "draft", user_ids: [ gws_user.id ]
    )
  end

  before { login_user user1 }

  context "draft post is not shown in the list" do
    it do
      visit gws_circular_main_path(site: site)
      within ".index" do
        expect(page).to have_css(".list-item", count: 0)
      end

      visit gws_portal_path(site: site)
      within first(".portlet-model-circular") do
        expect(page).to have_css(".list-item", count: 0)
      end
    end
  end
end
