require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder1) { create :gws_share_folder }
  let!(:folder2) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder1.id, category_ids: [category.id], deleted: Time.zone.now }

  before { login_gws_user }

  it do
    visit gws_share_files_path(site: site)
    click_on I18n.t('ss.navi.trash')
    expect(page).to have_content(item.name)

    # switch to folder1
    within "#content-navi" do
      click_on folder1.name
    end

    expect(page).to have_content(item.name)
    within "#content-navi" do
      expect(page).to have_css(".tree-item.is-current", text: folder1.name)
    end

    # switch to folder2
    within "#content-navi" do
      click_on folder2.name
    end

    expect(page).to have_no_content(item.name)
    within "#content-navi" do
      expect(page).to have_css(".tree-item.is-current", text: folder2.name)
    end
  end
end
