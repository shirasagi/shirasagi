require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }
  let!(:cate2) { create(:gws_circular_category) }
  let!(:post1) do
    create(
      :gws_circular_post, due_date: now + 3.days, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
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
      :gws_circular_post, due_date: now + 1.day, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
      state: "draft"
    )
  end

  describe "delete all" do
    before { login_gws_user }

    it do
      visit gws_circular_admins_path(site)

      within first(".list-item") do
        first("input[type='checkbox']").click
      end
      within ".list-head" do
        page.accept_confirm do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      post1.reload
      post2.reload
      post3.reload
      expect(post1.deleted).to be_blank
      expect(post2.deleted).to be_blank
      expect(post3.deleted).to be_present

      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.trash")

      within first(".list-item") do
        first("input[type='checkbox']").click
      end
      within ".list-head" do
        page.accept_confirm do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Circular::Post.all.topic.count).to eq 2
      expect { Gws::Circular::Post.all.find(post3.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
