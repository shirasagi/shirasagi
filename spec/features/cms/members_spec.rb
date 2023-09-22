require 'spec_helper'

describe "cms_members", type: :feature do
  subject(:site) { cms_site }
  subject(:item) { Cms::Member.last }
  subject(:index_path) { cms_members_path site.id }
  subject(:new_path) { new_cms_member_path site.id }
  subject(:show_path) { cms_member_path site.id, item }
  subject(:edit_path) { edit_cms_member_path site.id, item }
  subject(:delete_path) { delete_cms_member_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[email]", with: "member_sample@example.jp"
        fill_in "item[in_password]", with: "abc123"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
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
  end

  context "search in index", js: true do
    before { login_cms_user }

    it do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[email]", with: "member_sample@example.jp"
        fill_in "item[in_password]", with: "abc123"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      member = Cms::Member.site(site).find_by(name: "sample")
      expect(member.name).to eq "sample"
      expect(member.email).to eq "member_sample@example.jp"
      expect(member.password).to eq SS::Crypto.crypt("abc123")
      expect(member.state).to eq "disabled"

      #
      # keyword search
      #
      visit index_path
      expect(page).to have_css(".list-item", count: 1)
      expect(page).to have_css(".list-item .info", text: member.name)
      expect(page).to have_css(".list-item .state", text: I18n.t("cms.options.member_state.#{member.state}"))

      within ".index-search" do
        fill_in "s[keyword]", with: "abc123"
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", count: 0)

      within ".index-search" do
        fill_in "s[keyword]", with: member.name
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", count: 1)
      expect(page).to have_css(".list-item .info", text: member.name)

      #
      # state search
      #
      visit index_path
      expect(page).to have_css(".list-items .info", text: member.name)

      within ".index-search" do
        select I18n.t("cms.options.member_state.#{member.state}"), from: "s[state]"
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", count: 1)
      expect(page).to have_css(".list-item .info", text: member.name)

      within ".index-search" do
        state = (%w(disabled enabled temporary) - [ member.state ]).sample
        select I18n.t("cms.options.member_state.#{state}"), from: "s[state]"
        click_button I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", count: 0)
    end
  end
end
