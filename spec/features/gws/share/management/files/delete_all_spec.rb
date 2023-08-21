require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], deleted: Time.zone.now }

  before { login_gws_user }

  it do
    folder.update_folder_descendants_file_info
    folder.reload
    expect(folder.descendants_files_count).to eq 1
    expect(folder.descendants_total_file_size).to eq item.size

    visit gws_share_files_path(site: site)
    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end

    click_on I18n.t('ss.navi.trash')
    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end
    expect(page).to have_content(item.name)

    wait_event_to_fire("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
    within ".list-head-action" do
      page.accept_confirm do
        click_on I18n.t("ss.links.delete")
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    within "#content-navi" do
      expect(page).to have_css(".tree-item", text: folder.name)
    end

    expect(Gws::Share::File.where(id: item.id)).to be_blank

    folder.reload
    expect(folder.descendants_files_count).to eq 0
    expect(folder.descendants_total_file_size).to eq 0
  end
end
