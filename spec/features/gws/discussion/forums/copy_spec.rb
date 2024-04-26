require 'spec_helper'

describe "gws_discussion_forums", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:copy_path) { copy_gws_discussion_forum_path(mode: '-', site: site, id: forum) }

  before { login_gws_user }

  it "#copy" do
    visit copy_path

    within "form#item-form" do
      fill_in "item[name]", with: "copy"
      click_button I18n.t('ss.buttons.save')
    end

    item = Gws::Discussion::Forum.where(name: "copy").first
    expect(item).to be_present
  end
end
