require 'spec_helper'

describe "gws_discussion_todos", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:forum1) { create :gws_discussion_forum, member_ids: [ gws_user.id ] }
  let!(:forum2) { create :gws_discussion_forum, member_ids: [ gws_user.id ] }
  let!(:item) do
    create(
      :gws_schedule_todo, cur_site: site, cur_user: gws_user, member_ids: [ gws_user.id ],
      in_discussion_forum: true, discussion_forum: forum2
    )
  end

  before { login_gws_user }

  context "with own forum" do
    it do
      visit gws_discussion_forum_todo_path(site: site, mode: '-', forum_id: forum2.id, id: item.id)
      expect(status_code).to eq 200
      within "#addon-basic" do
        expect(page).to have_content(item.name)
      end
    end
  end

  context "with other forum" do
    it do
      visit gws_discussion_forum_todo_path(site: site, mode: '-', forum_id: forum1.id, id: item.id)
      expect(status_code).to eq 404

      page.driver.post finish_gws_discussion_forum_todo_path(site: site, mode: '-', forum_id: forum1.id, id: item.id)
      expect(page.driver.response.status).to eq 404

      item.reload
      expect(item.discussion_forum_id).to eq forum2.id
      expect(item.todo_state).to eq "unfinished"
    end
  end
end
