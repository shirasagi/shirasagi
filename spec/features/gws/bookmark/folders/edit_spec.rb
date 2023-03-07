require 'spec_helper'

describe "gws_bookmark_folders", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:basename) { I18n.t("gws/bookmark.root_folder") }
  let(:basename1) { unique_id }
  let(:basename2) { unique_id }
  let(:basename3) { unique_id }
  let(:new_basename) { unique_id }

  let!(:folder) { user.bookmark_root_folder(site) }
  let!(:item1) { create :gws_bookmark_folder, cur_user: user, in_parent: folder.id, in_basename: { ja: basename1 } }
  let!(:item2) { create :gws_bookmark_folder, cur_user: user, in_parent: item1.id, in_basename: { ja: basename2 } }
  let!(:item3) { create :gws_bookmark_folder, cur_user: user, in_parent: folder.id, in_basename: { ja: basename3 } }

  let(:index_path) { gws_bookmark_folders_path site }

  before { login_gws_user }

  context "created folders" do
    it "#index" do
      expect(Gws::Bookmark::Folder.count).to eq 4
      expect(Gws::Bookmark::Folder.where(folder_type: "specified").count).to eq 1
      expect(Gws::Bookmark::Folder.where(folder_type: "general").count).to eq 3
      expect(folder.depth).to eq 1
      expect(item1.depth).to eq 2
      expect(item2.depth).to eq 3
      expect(item3.depth).to eq 2

      visit index_path
      within ".list-items" do
        expect(page).to have_selector(".list-item", count: 4)
        expect(page).to have_css(".list-item", text: folder.name)
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
      end
    end
  end

  context "edit folder" do
    it "#edit" do
      visit edit_gws_bookmark_folder_path site, folder
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.depth).to eq 1
      expect(folder.name).to eq basename

      item1.reload
      expect(item1.depth).to eq 2
      expect(item1.name).to eq "#{basename}/#{basename1}"

      item2.reload
      expect(item2.depth).to eq 3
      expect(item2.name).to eq "#{basename}/#{basename1}/#{basename2}"

      item3.reload
      expect(item3.depth).to eq 2
      expect(item3.name).to eq "#{basename}/#{basename3}"
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, folder
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: ""
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("errors.messages.blank"))
      end
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, folder
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: new_basename
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.depth).to eq 1
      expect(folder.name).to eq new_basename

      item1.reload
      expect(item1.depth).to eq 2
      expect(item1.name).to eq "#{new_basename}/#{basename1}"

      item2.reload
      expect(item2.depth).to eq 3
      expect(item2.name).to eq "#{new_basename}/#{basename1}/#{basename2}"

      item3.reload
      expect(item3.depth).to eq 2
      expect(item3.name).to eq "#{new_basename}/#{basename3}"
    end
  end

  context "edit item1" do
    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item1
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.depth).to eq 1
      expect(folder.name).to eq basename

      item1.reload
      expect(item1.depth).to eq 2
      expect(item1.name).to eq "#{basename}/#{basename1}"

      item2.reload
      expect(item2.depth).to eq 3
      expect(item2.name).to eq "#{basename}/#{basename1}/#{basename2}"

      item3.reload
      expect(item3.depth).to eq 2
      expect(item3.name).to eq "#{basename}/#{basename3}"
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item1
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: ""
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("errors.messages.blank"))
      end
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item1
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: basename3
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("mongoid.errors.models.gws/bookmark/folder.same_folder_exists"))
      end
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item1
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: new_basename
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.depth).to eq 1
      expect(folder.name).to eq basename

      item1.reload
      expect(item1.depth).to eq 2
      expect(item1.name).to eq "#{basename}/#{new_basename}"

      item2.reload
      expect(item2.depth).to eq 3
      expect(item2.name).to eq "#{basename}/#{new_basename}/#{basename2}"

      item3.reload
      expect(item3.depth).to eq 2
      expect(item3.name).to eq "#{basename}/#{basename3}"
    end
  end

  context "edit item2" do
    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item2
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.depth).to eq 1
      expect(folder.name).to eq basename

      item1.reload
      expect(item1.depth).to eq 2
      expect(item1.name).to eq "#{basename}/#{basename1}"

      item2.reload
      expect(item2.depth).to eq 3
      expect(item2.name).to eq "#{basename}/#{basename1}/#{basename2}"

      item3.reload
      expect(item3.depth).to eq 2
      expect(item3.name).to eq "#{basename}/#{basename3}"
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item2
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: ""
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("errors.messages.blank"))
      end
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item2
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: basename3
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.depth).to eq 1
      expect(folder.name).to eq basename

      item1.reload
      expect(item1.depth).to eq 2
      expect(item1.name).to eq "#{basename}/#{basename1}"

      item2.reload
      expect(item2.depth).to eq 3
      expect(item2.name).to eq "#{basename}/#{basename1}/#{basename3}"

      item3.reload
      expect(item3.depth).to eq 2
      expect(item3.name).to eq "#{basename}/#{basename3}"
    end

    it "#edit" do
      visit edit_gws_bookmark_folder_path site, item2
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: new_basename
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      folder.reload
      expect(folder.depth).to eq 1
      expect(folder.name).to eq basename

      item1.reload
      expect(item1.depth).to eq 2
      expect(item1.name).to eq "#{basename}/#{basename1}"

      item2.reload
      expect(item2.depth).to eq 3
      expect(item2.name).to eq "#{basename}/#{basename1}/#{new_basename}"

      item3.reload
      expect(item3.depth).to eq 2
      expect(item3.name).to eq "#{basename}/#{basename3}"
    end
  end
end
