require 'spec_helper'

describe "gws_discussion_todos", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:forum) { create :gws_discussion_forum }
    let!(:index_path) { gws_discussion_forum_todos_path(site: site.id, forum_id: forum.id) }
    let!(:new_path) { new_gws_discussion_forum_todo_path(site: site.id, forum_id: forum.id) }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path

      text = "text-#{unique_id}"
      within "form#item-form" do
        fill_in "item[text]", with: text
        click_button "保存"
      end

      #expect(page).to have_link("[#{forum.name}]")
      #expect(page).to have_text(text)
    end
  end
end
