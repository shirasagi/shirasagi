require 'spec_helper'

describe "gws_bookmark_folders", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:item) { create :gws_bookmark_folder }
  let(:folder) { user.bookmark_root_folder(site) }

  let(:index_path) { gws_bookmark_folders_path site }
  let(:new_path) { new_gws_bookmark_folder_path site }
  let(:show_path) { gws_bookmark_folder_path site, item }
  let(:edit_path) { edit_gws_bookmark_folder_path site, item }
  let(:delete_path) { delete_gws_bookmark_folder_path site, item }

  let(:name) { unique_id }
  let(:order) { 20 }

  before { login_gws_user }

  it "#index" do
    visit index_path
    expect(current_path).not_to eq sns_login_path

    within ".list-items" do
      expect(page).to have_selector(".list-item", count: 1)
      expect(page).to have_css(".list-item", text: folder.name)
    end
  end

  it "#new" do
    visit new_path
    within "form#item-form" do
      fill_in 'item[in_basename][ja]', with: name
      fill_in 'item[order]', with: order
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

    within "#addon-basic" do
      expect(page).to have_css("dd", text: name)
      expect(page).to have_css("dd", text: order)
      expect(page).to have_css("dd", text: folder.name)
    end
  end

  it "#show" do
    visit show_path
    expect(current_path).not_to eq sns_login_path

    within "#addon-basic" do
      expect(page).to have_css("dd", text: folder.name)
    end
  end

  it "#edit" do
    visit edit_path
    within "form#item-form" do
      fill_in 'item[in_basename][ja]', with: name
      fill_in 'item[order]', with: order
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

    within "#addon-basic" do
      expect(page).to have_css("dd", text: name)
      expect(page).to have_css("dd", text: order)
      expect(page).to have_css("dd", text: folder.name)
    end
  end

  it "#delete" do
    visit delete_path
    within "form#item-form" do
      click_button I18n.t('ss.buttons.delete')
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
  end
end
