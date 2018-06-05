require 'spec_helper'

describe "gws_discussion_todos", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }
    let(:forum) { create :gws_discussion_forum }
    let(:index_path) { gws_discussion_forum_todos_path(site: site.id, forum_id: forum.id, mode: '-') }
    let(:new_path) { new_gws_discussion_forum_todo_path(site: site.id, forum_id: forum.id, mode: '-') }
    let(:text) { "text-#{unique_id}" }

    before { login_gws_user }

    it do
      visit new_path
      within "form#item-form" do
        fill_in "item[text]", with: text
        click_button I18n.t('ss.buttons.save')
      end

      visit index_path
      expect(page).to have_css('a.fc-event .fc-title', text: "[#{forum.name}]")
    end
  end
end
