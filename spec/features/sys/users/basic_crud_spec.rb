require 'spec_helper'

describe "sys_users", type: :feature, dbscope: :example do
  let(:item) { create :sys_user_sample }
  let(:index_path) { sys_users_path }
  let(:new_path) { new_sys_user_path }
  let(:show_path) { sys_user_path item }
  let(:edit_path) { edit_sys_user_path item }
  let(:delete_path) { delete_sys_user_path item }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth", js: true do
    before { login_sys_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[email]", with: "sample@example.jp"
        expect(page).to have_css('#item_email_errors', text: '')
        fill_in "item[in_password]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "delete disabled user" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path

      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path

      within ".index-search" do
        fill_in "s[keyword]", with: item.name
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_content(item.name)
    end

    it "delete_all disabled user" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path

      within ".index-search" do
        fill_in "s[keyword]", with: item.name
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-items", count: 1)

      find('.list-head label.check input').set(true)
      click_button I18n.t("ss.links.delete")
      page.accept_alert
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      within ".index-search" do
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_content(item.name)
    end
  end
end
