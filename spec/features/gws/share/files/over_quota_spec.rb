require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let(:index_path) { gws_share_folder_files_path site, folder }
  let(:filepath) { tmpfile { |file| file.write('0123456789') } }
  let(:filesize) { ::File.size(filepath) }

  before { login_gws_user }

  context "when file is under quotas" do
    before do
      folder.share_max_file_size = filesize
      folder.share_max_folder_size = filesize
      folder.save!

      site.share_max_file_size = filesize
      site.share_files_capacity = filesize
      site.save!
    end

    it do
      visit index_path
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        within "#addon-basic" do
          click_on I18n.t("ss.links.upload")
        end
      end

      wait_for_ajax do
        attach_file "item[in_files][]", filepath
        click_on I18n.t("ss.buttons.attach")
      end

      within "form#item-form" do
        fill_in "item[memo]", with: unique_id
        within "footer.send" do
          click_on I18n.t("ss.links.upload")
        end
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "#gws-share-file-folder-list" do
        expect(page).to have_css(".tree-item", text: folder.name)
      end
    end
  end

  context "when file is over quotas" do
    shared_examples "over a quota" do
      it do
        visit index_path
        click_on I18n.t("ss.links.new")

        within "form#item-form" do
          within "#addon-basic" do
            click_on I18n.t("ss.links.upload")
          end
        end

        wait_for_ajax do
          attach_file "item[in_files][]", filepath
          click_on I18n.t("ss.buttons.attach")
        end

        within "form#item-form" do
          fill_in "item[memo]", with: unique_id
          within "footer.send" do
            click_on I18n.t("ss.links.upload")
          end
        end

        expect(page).to have_css("#errorExplanation", text: msg)
      end
    end

    context "over folder's share_max_file_size" do
      let(:msg) do
        I18n.t(
          "mongoid.errors.models.gws/share/file.file_size_exceeds_limit",
          size: filesize.to_s(:human_size), limit: folder.share_max_file_size.to_s(:human_size)
        )
      end

      before do
        folder.share_max_file_size = filesize - 1
        folder.save!
      end

      include_context "over a quota"
    end

    context "over folder's share_max_folder_size" do
      let(:msg) do
        I18n.t(
          "mongoid.errors.models.gws/share/file.file_size_exceeds_folder_limit",
          size: filesize.to_s(:human_size), limit: folder.share_max_folder_size.to_s(:human_size)
        )
      end

      before do
        folder.share_max_folder_size = filesize - 1
        folder.save!
      end

      include_context "over a quota"
    end

    context "over site's share_max_file_size" do
      let(:msg) do
        I18n.t(
          "mongoid.errors.models.gws/share/file.file_size_exceeds_limit",
          size: filesize.to_s(:human_size), limit: site.share_max_file_size.to_s(:human_size)
        )
      end

      before do
        site.share_max_file_size = filesize - 1
        site.save!
      end

      include_context "over a quota"
    end

    context "over site's share_files_capacity" do
      let(:msg) do
        I18n.t(
          "mongoid.errors.models.gws/share/file.file_size_exceeds_capacity",
          size: filesize.to_s(:human_size), limit: site.share_files_capacity.to_s(:human_size)
        )
      end

      before do
        site.share_files_capacity = filesize - 1
        site.save!
      end

      include_context "over a quota"
    end
  end

  context "when file is over quotas on updating" do
    let(:filepath2) { tmpfile { |file| file.write('0123456789' + '0') } }
    let(:filesize2) { ::File.size(filepath2) }
    let(:msg) do
      I18n.t(
        "mongoid.errors.models.gws/share/file.file_size_exceeds_capacity",
        size: filesize2.to_s(:human_size), limit: site.share_files_capacity.to_s(:human_size)
      )
    end

    before do
      folder.share_max_file_size = filesize
      folder.share_max_folder_size = filesize
      folder.save!

      site.share_max_file_size = filesize
      site.share_files_capacity = filesize
      site.save!

      Fs::UploadedFile.create_from_file(filepath, content_type: 'application/octet-stream') do |f|
        create(:gws_share_file, folder: folder, in_file: f)
      end
    end

    it do
      visit index_path
      click_on ::File.basename(filepath)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        attach_file "item[in_file]", filepath2
        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("#errorExplanation", text: msg)
    end
  end
end
