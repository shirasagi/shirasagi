require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:root_folder) { create :gws_share_folder }
  let!(:folder1) { create :gws_share_folder, name: "#{root_folder.name}/#{unique_id}" }
  let!(:folder2) { create :gws_share_folder, name: "#{root_folder.name}/#{unique_id}" }
  let!(:file_path1) { tmpfile(extname: ".txt") { |f| f.puts Array.new(rand(3..10)) { unique_id }.join("\n") } }
  let!(:file_path2) { tmpfile(extname: ".txt") { |f| f.puts Array.new(rand(3..10)) { unique_id }.join("\n") } }
  let!(:file_path3) { tmpfile(extname: ".txt") { |f| f.puts Array.new(rand(3..10)) { unique_id }.join("\n") } }

  before { login_gws_user }

  context "basic crud" do
    it do
      # Create #1
      visit gws_share_files_path(site)
      click_on root_folder.trailing_name
      click_on folder1.trailing_name
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        within "#addon-basic" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", file_path1
        click_on I18n.t("ss.buttons.attach")
      end
      within "form#item-form" do
        within "#selected-files" do
          expect(page).to have_css(".file-view", text: ::File.basename(file_path1))
        end
        within "footer.send" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # Create #2
      visit gws_share_files_path(site)
      click_on root_folder.trailing_name
      click_on folder2.trailing_name
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        within "#addon-basic" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", file_path2
        click_on I18n.t("ss.buttons.attach")
      end
      within "form#item-form" do
        within "#selected-files" do
          expect(page).to have_css(".file-view", text: ::File.basename(file_path2))
        end
        within "footer.send" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # Create #3
      visit gws_share_files_path(site)
      click_on root_folder.trailing_name
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        within "#addon-basic" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", file_path3
        click_on I18n.t("ss.buttons.attach")
      end
      within "form#item-form" do
        within "#selected-files" do
          expect(page).to have_css(".file-view", text: ::File.basename(file_path3))
        end
        within "footer.send" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Share::File.all.count).to eq 3
      file1 = Gws::Share::File.all.find_by(folder_id: folder1.id)
      expect(file1.name).to eq ::File.basename(file_path1)
      expect(file1.filename).to eq ::File.basename(file_path1)
      expect(file1.size).to eq ::File.size(file_path1)
      expect(file1.content_type).to eq "text/plain"

      file2 = Gws::Share::File.all.find_by(folder_id: folder2.id)
      expect(file2.name).to eq ::File.basename(file_path2)
      expect(file2.filename).to eq ::File.basename(file_path2)
      expect(file2.size).to eq ::File.size(file_path2)
      expect(file2.content_type).to eq "text/plain"

      file3 = Gws::Share::File.all.find_by(folder_id: root_folder.id)
      expect(file3.name).to eq ::File.basename(file_path3)
      expect(file3.filename).to eq ::File.basename(file_path3)
      expect(file3.size).to eq ::File.size(file_path3)
      expect(file3.content_type).to eq "text/plain"

      folder1.reload
      expect(folder1.descendants_files_count).to eq 1
      expect(folder1.descendants_total_file_size).to eq file1.size

      folder2.reload
      expect(folder2.descendants_files_count).to eq 1
      expect(folder2.descendants_total_file_size).to eq file2.size

      root_folder.reload
      expect(root_folder.descendants_files_count).to eq 3
      expect(root_folder.descendants_total_file_size).to eq file1.size + file2.size + file3.size
    end
  end
end
