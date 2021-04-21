require 'spec_helper'

describe "sys_notice", type: :feature, dbscope: :example do
  let(:name) { unique_id }
  let(:name2) { unique_id }
  let(:html) { "<p>#{unique_id}</p>" }

  before { login_sys_user }

  describe "basic crud" do
    it do
      #
      # Create
      #
      visit sys_notice_index_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name

        first("#item_notice_severity").click

        first("#item_notice_target_login_view").click
        first("#item_notice_target_cms_admin").click
        first("#item_notice_target_gw_admin").click
        first("#item_notice_target_webmail_admin").click
        first("#item_notice_target_sys_admin").click

        fill_in "item[html]", with: html

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Sys::Notice.all.count).to eq 1
      Sys::Notice.all.first.tap do |notice|
        expect(notice.name).to eq name
        expect(notice.html).to eq html
        expect(notice.notice_severity).to eq "high"
        expect(notice.notice_target).to have_at_least(5).items
        expect(notice.notice_target).to include("login_view", "cms_admin", "gw_admin", "webmail_admin", "sys_admin")
      end

      #
      # Update
      #
      visit sys_notice_index_path
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Sys::Notice.all.count).to eq 1
      Sys::Notice.all.first.tap do |notice|
        expect(notice.name).to eq name2
      end

      #
      # Delete
      #
      visit sys_notice_index_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Sys::Notice.all.count).to eq 0
    end
  end
end
