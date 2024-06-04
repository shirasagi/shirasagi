require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }
  let!(:post1) do
    create(
      :gws_circular_post, due_date: now + 1.day, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
      state: "public"
    )
  end

  before do
    post1.set_seen!(user1)
    post1.reload
  end

  describe "article state" do
    before { login_gws_user }

    it do
      visit gws_circular_admins_path(site)
      click_on post1.name

      within ".gws-board" do
        count = post1.seen_users.active.count
        total = post1.sorted_overall_members.active.count
        msg = I18n.t('gws/circular.seen_user_info.format', count: count, total: total)
        expect(page).to have_css("dd", text: msg)

        wait_for_cbox_opened do
          click_on I18n.t('gws/circular.seen_user_info.more')
        end
      end

      within_cbox do
        within "table.index [data-user-id='#{user1.id}']" do
          seen_at = post1.seen_at(user1)
          expect(page).to have_css("td.browsed", text: I18n.t('gws/board.options.browsed_state.read'))
          expect(page).to have_css("td.browsed", text: I18n.l(seen_at, format: :picker))
        end
        within "table.index [data-user-id='#{gws_user.id}']" do
          expect(page).to have_css("td.browsed", text: I18n.t('gws/circular.post.unseen'))
        end
      end
    end
  end
end
