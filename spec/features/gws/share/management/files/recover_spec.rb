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

    expect(item.histories.count).to eq 1

    visit gws_share_files_path(site: site)
    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end

    click_on I18n.t('ss.navi.trash')
    within ".tree-navi" do
      expect(page).to have_css(".item-name", text: folder.name)
    end

    click_on item.name
    click_on I18n.t("ss.links.restore")

    within "form#item-form" do
      click_on I18n.t("ss.buttons.restore")
    end

    wait_for_notice I18n.t('ss.notice.restored')
    within "#content-navi" do
      expect(page).to have_css(".tree-item", text: folder.name)
    end

    item.reload
    expect(item.deleted).to be_blank

    expect(item.histories.count).to eq 2
    item.histories.first.tap do |history|
      expect(history.name).to eq item.name
      expect(history.mode).to eq "undelete"
      expect(history.model).to eq item.class.model_name.i18n_key.to_s
      expect(history.model_name).to eq I18n.t("mongoid.models.#{item.class.model_name.i18n_key}")
      expect(history.item_id).to eq item.id.to_s
      expect(::Fs.file?(history.path)).to be_truthy
      expect(history.path).to eq item.histories.last.path
    end

    folder.reload
    expect(folder.descendants_files_count).to eq 1
    expect(folder.descendants_total_file_size).to eq item.size
  end
end
