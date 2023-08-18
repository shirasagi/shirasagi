require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], memo: "test" }
  let(:categorized_item) { create :gws_share_file, name: "categorized", folder_id: folder.id, category_ids: [category.id] }
  let(:uncategorized_item) { create :gws_share_file, name: "uncategorized", folder_id: folder.id, category_ids: [] }
  let(:index_path) { gws_share_folder_files_path site, folder }
  let(:folder_path) { gws_share_folder_files_path site, folder }

  before { login_gws_user }

  it "index page with :category" do
    categorized_item
    uncategorized_item

    visit index_path
    within "#gws-share-file-folder-list .tree-navi" do
      expect(page).to have_link folder.name
    end
    within ".list-items" do
      expect(page).to have_link categorized_item.name
      expect(page).to have_link uncategorized_item.name
    end

    first('.gws-category-navi.dropdown a', text: I18n.t("gws.category")).click
    first('.gws-category-navi.dropdown a', text: category.name).click

    expect(page).to have_link categorized_item.name
    expect(page).to have_no_link uncategorized_item.name

    click_on categorized_item.name
    click_on I18n.t('ss.links.back_to_index')

    within "#gws-share-file-folder-list .tree-navi" do
      expect(page).to have_link folder.name
    end
    within ".list-items" do
      expect(page).to have_link categorized_item.name
    end
    expect(page).to have_no_link uncategorized_item.name
  end

  it "folder page with :category" do
    categorized_item
    uncategorized_item

    visit folder_path
    within "#gws-share-file-folder-list .tree-navi" do
      expect(page).to have_link folder.name
    end
    within ".list-items" do
      expect(page).to have_link categorized_item.name
      expect(page).to have_link uncategorized_item.name
    end

    first('.gws-category-navi.dropdown a', text: I18n.t("gws.category")).click
    first('.gws-category-navi.dropdown a', text: category.name).click

    expect(page).to have_link categorized_item.name
    expect(page).to have_no_link uncategorized_item.name

    click_on categorized_item.name
    click_on I18n.t('ss.links.back_to_index')

    within "#gws-share-file-folder-list .tree-navi" do
      expect(page).to have_link folder.name
    end
    within ".list-items" do
      expect(page).to have_link categorized_item.name
    end
    expect(page).to have_no_link uncategorized_item.name
  end
end
