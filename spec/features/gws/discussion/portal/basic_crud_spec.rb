require 'spec_helper'

describe "gws_discussion_portal", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:forum) { create :gws_discussion_forum }
    let!(:topic) { create :gws_discussion_topic }

    before { login_gws_user }

    it "#index" do
      visit gws_discussion_main_path(site: site.id, mode: '-')
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css(".gws-discussion-navi-forums .list-item")
      expect(page).to have_css(".gws-discussion-navi-topics .list-item")
    end
  end
end
