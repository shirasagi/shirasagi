require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create :gws_user, gws_role_ids: gws_user.gws_role_ids }
  let!(:user2) { create :gws_user, gws_role_ids: gws_user.gws_role_ids }

  let!(:memo1) do
    create(
      :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ gws_user.id.to_s ]
    )
  end
  let!(:memo2) do
    create(
      :gws_memo_message, cur_site: site, cur_user: user2, in_to_members: [ gws_user.id.to_s ]
    )
  end

  before do
    login_gws_user
  end

  context "filter by sender on clicking sender name" do
    it do
      visit gws_memo_messages_path(site: site)
      expect(page).to have_css(".list-item", count: 2)
      expect(page).to have_css(".list-item[data-id='#{memo1.id}']")
      expect(page).to have_css(".list-item[data-id='#{memo2.id}']")

      within ".list-item[data-id='#{memo1.id}']" do
        click_on user1.name
      end
      expect(page).to have_css(".gws-memo-search-label", text: user1.name)
      expect(page).to have_css(".list-item", count: 1)
      expect(page).to have_css(".list-item[data-id='#{memo1.id}']")
      expect(page).to have_no_css(".list-item[data-id='#{memo2.id}']")

      visit gws_memo_messages_path(site: site)
      within ".list-item[data-id='#{memo2.id}']" do
        click_on user2.name
      end
      expect(page).to have_css(".gws-memo-search-label", text: user2.name)
      expect(page).to have_css(".list-item", count: 1)
      expect(page).to have_no_css(".list-item[data-id='#{memo1.id}']")
      expect(page).to have_css(".list-item[data-id='#{memo2.id}']")

      # but subject is clicked then detail is shown
      within ".list-item[data-id='#{memo2.id}']" do
        click_on memo2.subject
      end
      expect(page).to have_css(".addon-view.gws-memo", text: memo2.text)
    end
  end
end
