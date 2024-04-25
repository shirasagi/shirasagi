require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], memo: "test" }
  let(:index_path) { gws_share_folder_files_path site, folder }

  before do
    clear_downloads
    login_gws_user
  end

  describe "download all" do
    context "when zip file is created on the fly" do
      it do
        visit index_path
        within ".tree-navi" do
          expect(page).to have_css(".item-name", text: folder.name)
        end
        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head label.check input').click }
        page.accept_confirm do
          find('.download-all').click
        end

        expect(page).to have_content(folder.name)
        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(item.name)
      end
    end

    context "when zip file is created in background job" do
      before do
        @save_config = SS.config.env.deley_download
        SS.config.replace_value_at(:env, :deley_download, { "min_filesize" => 0, "min_count" => 0 })
      end

      after do
        SS.config.replace_value_at(:env, :deley_download, @save_config)
      end

      it do
        visit index_path
        within ".tree-navi" do
          expect(page).to have_css(".item-name", text: folder.name)
        end
        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
        page.accept_confirm do
          find('.download-all').click
        end

        wait_for_notice I18n.t('gws.notice.delay_download_with_message').split("\n").first
        within "#gws-share-file-folder-list" do
          expect(page).to have_css(".tree-item", text: folder.name)
        end

        expect(enqueued_jobs.size).to eq 1
        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:job]).to eq Gws::CompressJob
          expect(enqueued_job[:args].first).to include("model" => "Gws::Share::File", "items" => [item.id])
        end
      end
    end
  end
end
