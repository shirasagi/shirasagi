require 'spec_helper'

describe "sys_ad", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let(:ss_file) { tmp_ss_file(SS::TempFile, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: SS::User.find(1)) }
    let(:time) { rand(1..10) }
    let(:width) { rand(1..100) }
    let(:url) { "http://example.com" }

    before { login_sys_user }

    it do
      ss_file
      visit sys_ad_path
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[time]", with: time
        fill_in "item[width]", with: width
        find('a.btn', text: I18n.t('ss.buttons.upload')).click
      end

      wait_for_cbox do
        expect(page).to have_content(ss_file.name)
        find("a[data-id='#{ss_file.id}']").click
      end

      within "form#item-form" do
        fill_in "item[link_urls][#{ss_file.id}]", with: url
        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      Sys::Setting.first.tap do |setting|
        expect(setting.time).to eq time
        expect(setting.width).to eq width
        expect(setting.file_ids.first).to eq ss_file.id
      end
    end
  end
end
