require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_board_topics_path site, '-', '-' }

  context "without login" do
    it do
      visit index_path
      expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
    end
  end

  context "without permissions" do
    let(:user) { create :gws_user, group_ids: [ site.id ] }

    it do
      login_user user
      visit index_path
      expect(page).to have_css(".index.gws-boards")
    end
  end
end
