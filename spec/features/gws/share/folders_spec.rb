require 'spec_helper'

describe "gws_share_folders", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:item) { create :gws_share_folder }
  let(:index_path) { gws_share_folders_path site }
  let(:edit_path) { edit_gws_share_folder_path site, item }
  let(:show_path) { gws_share_folder_path site, item }
  let(:delete_path) { delete_gws_share_folder_path site, item }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      item
      visit edit_path
      wait_for_ajax
      expect(page).to have_content('基本情報')
    end

    it "#show" do
      item
      visit show_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end
  end

  context "#delete with auth" do
    before { login_gws_user }

    # before do
    #   item
    #   item.class.create_download_directory(File.dirname(item.class.zip_path(item._id)))
    #   File.open(item.class.zip_path(item._id), "w").close
    # end

    it "#delete" do
      # expect(FileTest.exist?(item.class.zip_path(item._id))).to be_truthy
      visit delete_path
      within "form" do
        click_button "削除"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: '保存しました。')
      # expect(FileTest.exist?(item.class.zip_path(item._id))).to be_falsey
    end
  end

  context "with sub folder" do
    let(:subfolder_name1) { unique_id }
    let(:subfolder_name2) { unique_id }
    let(:item2) { create :gws_share_folder }

    before { login_gws_user }

    before do
      item
      item2
    end

    context 'basic crud' do
      it do
        visit index_path
        click_on I18n.t('ss.links.new')

        #
        # Create
        #
        within 'form#item-form' do
          fill_in 'item[in_basename]', with: subfolder_name1
          click_on I18n.t('gws/share.apis.folders.index')
        end

        within '#cboxLoadedContent' do
          click_on item.name
        end

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 1

        #
        # Update
        #
        visit index_path
        click_on "#{item.name}/#{subfolder_name1}"
        click_on I18n.t('ss.links.edit')

        within 'form#item-form' do
          fill_in 'item[in_basename]', with: subfolder_name2
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name2}").count).to eq 1

        #
        # Delete
        #
        visit index_path
        click_on "#{item.name}/#{subfolder_name2}"
        click_on I18n.t('ss.links.delete')

        within 'form' do
          click_on I18n.t('ss.buttons.delete')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name2}").count).to eq 0
      end
    end

    context 'move sub folder' do
      let!(:sub_folder) { create(:gws_share_folder, name: "#{item.name}/#{subfolder_name1}") }

      it do
        visit index_path
        click_on "#{item.name}/#{subfolder_name1}"
        click_on I18n.t('ss.links.move')

        within 'form#item-form' do
          click_on I18n.t('gws/share.apis.folders.index')
        end
        within '#cboxLoadedContent' do
          click_on item2.name
        end
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item2.name}/#{subfolder_name1}").count).to eq 1
      end
    end

    context 'move folder with sub folder' do
      let!(:sub_folder) { create(:gws_share_folder, name: "#{item.name}/#{subfolder_name1}") }

      it do
        visit index_path
        find("a.title[href=\"#{gws_share_folder_path(site, item)}\"]").click
        click_on I18n.t('ss.links.move')

        within 'form#item-form' do
          click_on I18n.t('gws/share.apis.folders.index')
        end
        within '#cboxLoadedContent' do
          click_on item2.name
        end
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        expect(Gws::Share::Folder.site(site).where(name: item.name).count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item2.name}/#{item.name}").count).to eq 1
        expect(Gws::Share::Folder.site(site).where(name: "#{item2.name}/#{item.name}/#{subfolder_name1}").count).to eq 1
      end
    end
  end
end
