require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }
  let!(:cate2) { create(:gws_circular_category) }
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

  describe "list search" do
    before { login_gws_user }

    context "with public state" do
      it do
        visit gws_circular_admins_path(site)
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: post1.name)
          expect(page).to have_css(".list-item .title", text: post2.name)
          expect(page).to have_css(".list-item .title", text: post3.name)
        end

        within ".list-head-search" do
          within "form.search" do
            select I18n.t("ss.options.state.public"), from: "s[state]"
          end
          click_on I18n.t("ss.buttons.search")
        end

        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: post1.name)
          expect(page).to have_css(".list-item .title", text: post2.name)
          expect(page).to have_no_css(".list-item .title", text: post3.name)
        end
      end
    end

    context "with draft state" do
      it do
        visit gws_circular_admins_path(site)
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: post1.name)
          expect(page).to have_css(".list-item .title", text: post2.name)
          expect(page).to have_css(".list-item .title", text: post3.name)
        end

        within ".list-head-search" do
          within "form.search" do
            select I18n.t("ss.options.state.draft"), from: "s[state]"
          end
          click_on I18n.t("ss.buttons.search")
        end

        within ".list-items" do
          expect(page).to have_no_css(".list-item .title", text: post1.name)
          expect(page).to have_no_css(".list-item .title", text: post2.name)
          expect(page).to have_css(".list-item .title", text: post3.name)
        end
      end
    end
  end
end
