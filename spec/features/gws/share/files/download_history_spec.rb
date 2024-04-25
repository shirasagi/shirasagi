require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  # let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], memo: "test" }
  let(:index_path) { gws_share_folder_files_path site, folder }
  let(:file_path1) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:file_path2) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }
  let(:name1) { ::File.basename(file_path1) }
  let(:name2) { ::File.basename(file_path2) }

  before { login_gws_user }

  describe "download from history" do
    it do
      # create
      visit gws_share_files_path(site)
      click_on folder.name
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        within "#addon-basic" do
          wait_for_cbox_opened do
            click_on I18n.t('ss.buttons.upload')
          end
        end
      end
      within_cbox do
        attach_file "item[in_files][]", file_path1
        wait_for_cbox_closed do
          click_on I18n.t("ss.buttons.attach")
        end
      end
      within "form#item-form" do
        expect(page).to have_content(name1)
        within "footer.send" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Share::File.all.count).to eq 1
      item = Gws::Share::File.all.first
      expect(item.name).to eq name1
      expect(item.filename).to eq name1

      expect(item.histories).to have(1).items
      expect(::Fs.file?(item.histories.first.path)).to be_truthy

      # edit
      visit gws_share_files_path(site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      click_on name1
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        attach_file "item[in_file]", file_path2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(item.histories.count).to eq 2
      expect(::Fs.file?(item.histories.first.path)).to be_truthy

      # download
      item.histories.first.tap do |history|
        visit gws_share_files_path(site)
        within ".tree-navi" do
          expect(page).to have_css(".item-name", text: folder.name)
        end
        click_on name1
        within "#addon-gws-agents-addons-share-history" do
          first(".addon-head h2").click
          within "tr#history-#{history.id}" do
            click_on I18n.t("ss.buttons.download")
          end
        end

        wait_for_download
        expect(::File.size(downloads.first)).to eq history.uploadfile_size
      end

      clear_downloads

      item.histories.last.tap do |history|
        visit gws_share_files_path(site)
        click_on name1
        within "#addon-gws-agents-addons-share-history" do
          first(".addon-head h2").click
          within "tr#history-#{history.id}" do
            click_on I18n.t("ss.buttons.download")
          end
        end

        wait_for_download
        expect(::File.size(downloads.first)).to eq history.uploadfile_size
      end
    end
  end
end
