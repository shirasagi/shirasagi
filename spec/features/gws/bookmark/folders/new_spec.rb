require 'spec_helper'

describe "gws_bookmark_folders", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:basename) { I18n.t("gws/bookmark.root_folder") }
  let(:basename1) { unique_id }
  let(:basename2) { unique_id }
  let(:basename3) { unique_id }

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

  context "under folder" do
    it "#new" do
      visit new_gws_bookmark_folder_path site
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("errors.messages.blank"))
      end
    end

    it "#new" do
      visit new_gws_bookmark_folder_path site
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: basename1
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("mongoid.errors.models.gws/bookmark/folder.same_folder_exists"))
      end

      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: basename3
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("mongoid.errors.models.gws/bookmark/folder.same_folder_exists"))
      end
    end

    it "#new" do
      visit new_gws_bookmark_folder_path site
      within "form#item-form" do
        fill_in 'item[in_basename][ja]', with: basename2
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Bookmark::Folder.count).to eq 5
      item = Gws::Bookmark::Folder.site(site).user(user).where(depth: 2).to_a.
        find { |item| item.name == "#{basename}/#{basename2}" }
      expect(item).not_to be_nil
    end
  end

  context "under item1" do
    it "#new" do
      visit new_gws_bookmark_folder_path site

      within "#item-form" do
        click_on I18n.t("gws/share.apis.folders.index")
      end
      wait_for_cbox do
        within "tr[data-id=\"#{folder.id}\"]" do
          expect(page).to have_text(folder.name)
          expect(page).to have_no_link(folder.name)
        end
        within "tr[data-id=\"#{item1.id}\"]" do
          expect(page).to have_text(item1.name)
          expect(page).to have_link(item1.name)
        end
        within "tr[data-id=\"#{item2.id}\"]" do
          expect(page).to have_text(item2.name)
          expect(page).to have_link(item2.name)
        end
        within "tr[data-id=\"#{item3.id}\"]" do
          expect(page).to have_text(item3.name)
          expect(page).to have_link(item3.name)
        end
        first("tr[data-id=\"#{item1.id}\"] a", text: item1.name).click
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("errors.messages.blank"))
      end
    end

    it "#new" do
      visit new_gws_bookmark_folder_path site

      within "#item-form" do
        fill_in 'item[in_basename][ja]', with: basename1
        click_on I18n.t("gws/share.apis.folders.index")
      end
      wait_for_cbox do
        within "tr[data-id=\"#{folder.id}\"]" do
          expect(page).to have_text(folder.name)
          expect(page).to have_no_link(folder.name)
        end
        within "tr[data-id=\"#{item1.id}\"]" do
          expect(page).to have_text(item1.name)
          expect(page).to have_link(item1.name)
        end
        within "tr[data-id=\"#{item2.id}\"]" do
          expect(page).to have_text(item2.name)
          expect(page).to have_link(item2.name)
        end
        within "tr[data-id=\"#{item3.id}\"]" do
          expect(page).to have_text(item3.name)
          expect(page).to have_link(item3.name)
        end
        first("tr[data-id=\"#{item1.id}\"] a", text: item1.name).click
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Bookmark::Folder.count).to eq 5
      item = Gws::Bookmark::Folder.site(site).user(user).where(depth: 3).to_a.
        find { |item| item.name == "#{basename}/#{basename1}/#{basename1}" }
      expect(item).not_to be_nil
    end

    it "#new" do
      visit new_gws_bookmark_folder_path site

      within "#item-form" do
        fill_in 'item[in_basename][ja]', with: basename2
        click_on I18n.t("gws/share.apis.folders.index")
      end
      wait_for_cbox do
        within "tr[data-id=\"#{folder.id}\"]" do
          expect(page).to have_text(folder.name)
          expect(page).to have_no_link(folder.name)
        end
        within "tr[data-id=\"#{item1.id}\"]" do
          expect(page).to have_text(item1.name)
          expect(page).to have_link(item1.name)
        end
        within "tr[data-id=\"#{item2.id}\"]" do
          expect(page).to have_text(item2.name)
          expect(page).to have_link(item2.name)
        end
        within "tr[data-id=\"#{item3.id}\"]" do
          expect(page).to have_text(item3.name)
          expect(page).to have_link(item3.name)
        end
        first("tr[data-id=\"#{item1.id}\"] a", text: item1.name).click
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      within "#errorExplanation" do
        expect(page).to have_text(I18n.t("mongoid.errors.models.gws/bookmark/folder.same_folder_exists"))
      end
    end

    it "#new" do
      visit new_gws_bookmark_folder_path site

      within "#item-form" do
        fill_in 'item[in_basename][ja]', with: basename3
        click_on I18n.t("gws/share.apis.folders.index")
      end
      wait_for_cbox do
        within "tr[data-id=\"#{folder.id}\"]" do
          expect(page).to have_text(folder.name)
          expect(page).to have_no_link(folder.name)
        end
        within "tr[data-id=\"#{item1.id}\"]" do
          expect(page).to have_text(item1.name)
          expect(page).to have_link(item1.name)
        end
        within "tr[data-id=\"#{item2.id}\"]" do
          expect(page).to have_text(item2.name)
          expect(page).to have_link(item2.name)
        end
        within "tr[data-id=\"#{item3.id}\"]" do
          expect(page).to have_text(item3.name)
          expect(page).to have_link(item3.name)
        end
        first("tr[data-id=\"#{item1.id}\"] a", text: item1.name).click
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Bookmark::Folder.count).to eq 5
      item = Gws::Bookmark::Folder.site(site).user(user).where(depth: 3).to_a.
        find { |item| item.name == "#{basename}/#{basename1}/#{basename3}" }
      expect(item).not_to be_nil
    end
  end
end
