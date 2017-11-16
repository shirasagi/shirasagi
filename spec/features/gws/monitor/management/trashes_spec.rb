require 'spec_helper'

describe "gws_monitor_management_trashes", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_monitor_topic, :gws_monitor_management_trashes }
  let(:item2) { create :gws_monitor_topic, :attend_group_ids }
  let(:item3) { create :gws_monitor_topic, :attend_group_ids, :article_deleted }
  let(:index_path) { gws_monitor_management_trashes_path site, gws_user }
  let(:new_path) { new_gws_monitor_management_trash_path site, gws_user }
  let(:delete_path) { delete_gws_monitor_management_trash_path site, item }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#index not deleted" do
      item2
      visit index_path
      wait_for_ajax
      expect(page).not_to have_content(item2.name)
    end

    it "#index deleted" do
      item3
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item3.name)
    end
  end

  context "#delete with auth", js: true do
    before { login_gws_user }

    before do
      item
      item.create_download_directory(File.dirname(item.zip_path))
      File.open(item.zip_path, "w").close
    end

    it "#delete" do
      expect(FileTest.exist?(item.zip_path)).to be_truthy
      visit delete_path
      within "form" do
        click_button "削除"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: '削除しました。')
      expect(FileTest.exist?(item.zip_path)).to be_falsey
    end
  end
end
