require 'spec_helper'

describe "gws_discussion_forums", type: :feature, dbscope: :example do
  context "copy", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_discussion_forum }
    let!(:copy_path) { copy_gws_discussion_forum_path site, item }

    before { login_gws_user }

    it "#copy" do
      visit copy_path

      within "form#item-form" do
        fill_in "item[name]", with: "copy"
        click_button "保存"
      end

      forum = Gws::Discussion::Forum.where(name: "copy").first
      expect(forum).not_to be nil
    end
  end
end
