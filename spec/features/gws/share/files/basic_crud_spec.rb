require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:filepath) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:ss_file) { tmp_ss_file(contents: filepath, site: site, user: gws_user) }

  before { login_gws_user }

  context "basic crud" do
    it do
      visit gws_share_files_path(site)
      click_on folder.name

      #
      # Create
      #
      click_on I18n.t("ss.links.new")
      click_on I18n.t("gws.apis.categories.index")
      wait_for_cbox do
        click_on category.name
      end
      within "form#item-form" do
        within "#addon-basic" do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      wait_for_cbox do
        expect(page).to have_content(ss_file.name)
        click_on ss_file.name
      end
      within "form#item-form" do
        fill_in "item[memo]", with: "new test"
      end
      within "footer.send" do
        click_on I18n.t('ss.buttons.upload')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within ".tree-navi" do
        expect(page).to have_content(folder.name)
      end

      expect(Gws::Share::File.all.count).to eq 1
      file = Gws::Share::File.all.first
      expect(file.site_id).to eq site.id
      expect(file.user_id).to eq gws_user.id
      expect(file.model).to eq "share/file"
      expect(file.state).to eq "closed"
      expect(file.name).to eq ::File.basename(filepath)
      expect(file.filename).to eq ::File.basename(filepath)
      expect(file.size).to be_present
      expect(file.content_type).to eq "image/png"
      expect(file.category_ids).to eq [ category.id ]
      expect(file.memo).to eq "new test"
      expect(file.folder_id).to eq folder.id

      expect(file.histories.count).to eq 1
      file.histories.first.tap do |history|
        expect(history.uploadfile_name).to eq file.name
        expect(history.uploadfile_filename).to eq file.filename
        expect(history.uploadfile_size).to eq file.size
        expect(history.uploadfile_content_type).to eq file.content_type
        expect(history.name).to eq file.name
        expect(history.mode).to eq "create"
        expect(history.model).to eq file.class.model_name.i18n_key.to_s
        expect(history.model_name).to eq I18n.t("mongoid.models.#{file.class.model_name.i18n_key}")
        expect(history.item_id).to eq file.id.to_s
        expect(::Fs.file?(history.path)).to be_truthy
      end

      folder.reload
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq file.size

      #
      # Update
      #
      visit gws_share_files_path(site)
      click_on folder.name
      click_on file.name
      expect(page).to have_content(file.memo)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        fill_in "item[memo]", with: "edited"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # within ".tree-navi" do
      #   expect(page).to have_content(folder.name)
      # end

      file.reload
      expect(file.name).to eq "modify"
      expect(file.memo).to eq "edited"

      expect(file.histories.count).to eq 2
      file.histories.first.tap do |history|
        expect(history.uploadfile_name).to eq file.name
        expect(history.uploadfile_filename).to eq file.filename
        expect(history.uploadfile_size).to eq file.size
        expect(history.uploadfile_content_type).to eq file.content_type
        expect(history.name).to eq file.name
        expect(history.mode).to eq "update"
        expect(history.model).to eq file.class.model_name.i18n_key.to_s
        expect(history.model_name).to eq I18n.t("mongoid.models.#{file.class.model_name.i18n_key}")
        expect(history.item_id).to eq file.id.to_s
        expect(::Fs.file?(history.path)).to be_truthy
        expect(history.path).to eq file.histories.last.path
      end

      #
      # Soft Delete
      #
      visit gws_share_files_path(site)
      click_on folder.name
      click_on file.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      within ".tree-navi" do
        expect(page).to have_content(folder.name)
      end

      file.reload
      expect(file.deleted).to be_present

      expect(file.histories.count).to eq 3
      file.histories.first.tap do |history|
        expect(history.name).to eq file.name
        expect(history.mode).to eq "delete"
        expect(history.model).to eq file.class.model_name.i18n_key.to_s
        expect(history.model_name).to eq I18n.t("mongoid.models.#{file.class.model_name.i18n_key}")
        expect(history.item_id).to eq file.id.to_s
        expect(::Fs.file?(history.path)).to be_truthy
        expect(history.path).to eq file.histories.last.path
      end

      folder.reload
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq file.size

      #
      # Hard Delete
      #
      history_paths = file.histories.map(&:path)
      expect(history_paths.all? { |path| ::Fs.file?(path) }).to be_truthy
      visit gws_share_files_path(site)
      click_on I18n.t("ss.links.trash")
      click_on folder.name
      click_on file.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect { Gws::Share::File.find(file.id) }.to raise_error Mongoid::Errors::DocumentNotFound
      expect(file.histories.count).to eq 0
      expect(history_paths.any? { |path| ::Fs.file?(path) }).to be_falsey

      folder.reload
      expect(folder.descendants_files_count).to eq 0
      expect(folder.descendants_total_file_size).to eq 0

      within "#content-navi" do
        expect(page).to have_css(".tree-item", text: folder.name)
      end
    end
  end
end
