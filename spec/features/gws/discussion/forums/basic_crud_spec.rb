require 'spec_helper'

describe "gws_discussion_forums", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:index_path) { gws_discussion_forums_path(mode: '-', site: site) }
  let!(:new_path) { new_gws_discussion_forum_path(mode: '-', site: site) }
  let!(:show_path) { gws_discussion_forum_path(mode: '-', site: site, id: forum) }
  let!(:edit_path) { edit_gws_discussion_forum_path(mode: '-', site: site, id: forum) }
  let!(:delete_path) { soft_delete_gws_discussion_forum_path(mode: '-', site: site, id: forum) }

  before { login_gws_user }

  it "#index" do
    visit index_path
    expect(current_path).not_to eq sns_login_path
  end

  it "#new" do
    visit new_path

    name = "name-#{unique_id}"
    within "form#item-form" do
      fill_in "item[name]", with: name
      click_button I18n.t('ss.buttons.save')
    end
    expect(first('#addon-basic')).to have_text(name)
  end

  it "#show" do
    visit show_path
    expect(current_path).not_to eq sns_login_path
  end

  it "#edit" do
    visit edit_path

    name = "modify-#{unique_id}"
    within "form#item-form" do
      fill_in "item[name]", with: name
      click_button I18n.t('ss.buttons.save')
    end
    expect(first('#addon-basic')).to have_text(name)
  end

  it "#delete" do
    visit delete_path
    within "form#item-form" do
      click_button I18n.t('ss.buttons.delete')
    end
    expect(current_path).to eq index_path
  end
end
