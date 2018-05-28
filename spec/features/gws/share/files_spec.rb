require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, tmpdir: true do
  let(:site) { gws_site }
  let(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id] }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let(:top_path) { gws_share_files_path site }
  let(:index_path) { gws_share_folder_files_path site, folder }
  let(:folder_path) { gws_share_folder_files_path site, folder }
  let(:new_path) { new_gws_share_folder_file_path site, folder }
  let(:show_path) { gws_share_folder_file_path site, folder, item }
  let(:edit_path) { edit_gws_share_folder_file_path site, folder, item }
  let(:delete_path) { delete_gws_share_folder_file_path site, folder, item }
  let(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: gws_user) }

  context "with auth" do
    before { login_gws_user }

    it "hide new menu on the top page", js: true do
      visit top_path
      wait_for_ajax
      expect(page).to have_no_content("新規作成")
    end

    it "appear new menu in writable folder", js: true do
      item.folder.user_ids = [gws_user.id]
      visit folder_path
      wait_for_ajax
      expect(page).to have_content("新規作成")
    end

    it "#new", js: true do
      # ensure that SS::TempFile was created
      ss_file

      visit new_path
      click_on I18n.t("gws.apis.categories.index")
      within "tbody.items" do
        click_on category.name
      end
      within "form#item-form" do
        # click_on I18n.t('ss.buttons.upload')
        find('a.btn', text: I18n.t('ss.buttons.upload')).click
      end
      within '#cboxLoadedContent' do
        expect(page).to have_content(ss_file.name)
        click_on ss_file.name
      end
      within "form#item-form" do
        find('input[type=submit]').click
      end
      expect(current_path).not_to eq new_path
      within ".tree-navi" do
        expect(page).to have_content(folder.name)
      end
    end

    it "#show" do
      item
      visit show_path
      expect(current_path).not_to eq sns_login_path
      expect(item.name).to eq "logo.png"
      expect(item.filename).to eq "logo.png"
      expect(item.state).to eq "closed"
      expect(item.content_type).to eq "image/png"
      expect(item.category_ids).to eq [category.id]
    end

    it "#edit", js: true do
      visit edit_path
      wait_for_ajax
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
      expect(page).to have_content(folder.name)
    end

    it "#delete", js: true do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(page).to have_no_content(item.name)
      expect(page).to have_content(folder.name)
    end

    context "#download_all with auth", js: true do
      before { login_gws_user }

      # after do
      #   temporary = SecureRandom.hex(4).to_s
      #   item.class.create_download_directory(gws_user._id,
      #                                        item.class.download_root_path,
      #                                        item.class.zip_path(gws_user._id, temporary))
      #   File.open(item.class.zip_path(gws_user._id, temporary), "w").close
      #   expect(FileTest.exist?(item.class.zip_path(gws_user._id, @created_zip_tmp_dir))).to be_falsey
      #   expect(FileTest.exist?(item.class.zip_path(gws_user._id, temporary))).to be_truthy
      # end

      it "#download_all" do
        item
        visit index_path
        find('.list-head label.check input').set(true)
        page.accept_confirm do
          find('.download-all').click
        end
        wait_for_ajax
        # @created_zip_tmp_dir = Dir.entries(item.class.download_root_path)
        #                            .find{ |elem| elem.include?(gws_user._id.to_s + "_") }.split("_").last
        # expect(FileTest.exist?(item.class.zip_path(gws_user._id, @created_zip_tmp_dir))).to be_truthy
      end
    end
  end
end
