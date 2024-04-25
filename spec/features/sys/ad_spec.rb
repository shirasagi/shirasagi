require 'spec_helper'

describe "sys_ad", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let(:ss_file) { tmp_ss_file(basename: "#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: sys_user) }
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
        wait_cbox_open do
          find('a.btn', text: I18n.t('ss.buttons.upload')).click
        end
      end

      wait_for_cbox do
        expect(page).to have_content(ss_file.name)
        click_on ss_file.name
      end

      within "form#item-form" do
        fill_in "item[link_urls][#{ss_file.id}]", with: url
        click_on I18n.t("ss.buttons.save")
      end

      wait_for_notice I18n.t('ss.notice.saved')

      Sys::Setting.first.tap do |setting|
        expect(setting.time).to eq time
        expect(setting.width).to eq width
        expect(setting.file_ids.first).to eq ss_file.id
      end
    end
  end
end
