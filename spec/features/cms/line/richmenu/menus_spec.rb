require 'spec_helper'

describe "cms/line/richmenu/menus", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }

  let!(:richmenu_group) { create :cms_line_richmenu_group }
  let!(:item) do
    create(:cms_line_richmenu_menu,
      group: richmenu_group,
      in_image: menu1_image,
      target: "default",
      area_size: 1,
      width: 800,
      height: 270,
      in_areas: menu1_in_areas1)
  end
  let!(:menu1_image) do
    Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/cms/line/richmenu_small1.png")
  end
  let(:menu1_in_areas1) do
    [ { x: 0, y: 0, width: 800, height: 270, type: "message", text: unique_id } ]
  end

  let(:new_path) { new_cms_line_richmenu_group_menu_path site, richmenu_group }
  let(:show_path) { cms_line_richmenu_group_menu_path site, richmenu_group, item }
  let(:edit_path) { edit_cms_line_richmenu_group_menu_path site, richmenu_group, item }

  context "basic crud" do
    let(:name) { unique_id }

    before { login_cms_user }

    it do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[order]", with: 10
        select I18n.t("cms.options.line_richmenu_target.switch"), from: "item[target]"
        attach_file 'item[in_image]', "#{Rails.root}/spec/fixtures/cms/line/richmenu_small1.png"
        fill_in "item[area_size]", with: 2
        fill_in "item[chat_bar_text]", with: unique_id
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-basic" do
        expect(page).to have_text name
        expect(page).to have_link "richmenu_small1.png"
      end
      within "#addon-cms-agents-addons-line-richmenu-area" do
        expect(page).to have_selector("a.area-name", count: 2)
        expect(page).to have_link "領域1"
        expect(page).to have_link "領域2"
      end
    end

    it do
      item.reload
      updated = item.updated

      visit edit_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-basic" do
        expect(page).to have_text item.name
        expect(page).to have_link "richmenu_small1.png"
      end

      item.reload
      expect(updated).to eq item.updated
    end

    it do
      item.reload
      updated = item.updated

      visit edit_path
      within "form#item-form" do
        attach_file 'item[in_image]', "#{Rails.root}/spec/fixtures/cms/line/richmenu_small2.png"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-basic" do
        expect(page).to have_text item.name
        expect(page).to have_link "richmenu_small2.png"
      end

      item.reload
      expect(updated).not_to eq item.updated
    end

    it do
      item.reload
      updated = item.updated

      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-basic" do
        expect(page).to have_text name
        expect(page).to have_link "richmenu_small1.png"
      end

      item.reload
      expect(updated).not_to eq item.updated
    end
  end

  context "crop" do
    before { login_cms_user }

    it do
      item.reload
      updated = item.updated

      visit show_path
      within "#addon-cms-agents-addons-line-richmenu-area" do
        expect(page).to have_text(menu1_in_areas1[0][:text])
        click_on I18n.t("ss.links.edit")
      end
      within ".area-form" do
        wait_for_js_ready
        click_on I18n.t("ss.buttons.reset")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".area-form" do
        expect(page).to have_no_text(menu1_in_areas1[0][:text])
      end

      item.reload
      expect(updated).not_to eq item.updated
    end
  end
end
