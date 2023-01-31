require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category1) { create :gws_share_category }
  let!(:category2) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category1.id], deleted: Time.zone.now }

  before { login_gws_user }

  it do
    visit gws_share_files_path(site: site)
    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end

    click_on I18n.t('ss.navi.trash')
    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end
    expect(page).to have_content(item.name)

    # switch to category1
    within ".gws-category-navi" do
      click_on I18n.t('gws.category')
      click_on category1.name
    end

    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end
    expect(page).to have_content(item.name)
    within ".gws-category-navi" do
      expect(page).to have_link(category1.name)
    end

    # switch to category2
    within ".gws-category-navi" do
      click_on category1.name
      click_on category2.name
    end

    expect(page).to have_no_content(item.name)
    within ".gws-category-navi" do
      expect(page).to have_link(category2.name)
    end

    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end
  end
end
