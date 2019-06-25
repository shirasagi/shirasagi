require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], memo: "test" }
  let(:index_path) { gws_share_folder_files_path site, folder }

  context "#download_all with auth" do
    before { login_gws_user }

    it "#download_all" do
      visit index_path
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.download-all').click
      end

      wait_for_download

      entry_names = ::Zip::File.open(downloads.first) do |entries|
        entries.map { |entry| entry.name }
      end
      expect(entry_names).to include(item.name)
    end
  end
end
