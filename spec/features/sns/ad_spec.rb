require 'spec_helper'

describe "login_ad", type: :feature, dbscope: :example, js: true do
  context "ad_links are existed" do
    let(:ss_file1) do
      tmp_ss_file(
        basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:ss_file2) do
      tmp_ss_file(
        basename: "keyvisual-#{unique_id}.jpg", contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
    end

    it "display ad" do
      setting = Sys::Setting.new
      setting.ad_links.build(url: unique_url, file_id: ss_file1.id, state: "show")
      setting.ad_links.build(url: unique_url, file_id: ss_file2.id, state: "show")
      setting.save!
      setting.reload

      visit sns_login_path
      wait_for_js_ready
      expect(page).to have_css(".login-image-box")
      expect(page).to have_css("img[src='#{ss_file1.url}']")
      expect(page).to have_css("img[src='#{ss_file2.url}']")

      visit sns_login_image_path
      wait_for_js_ready
      expect(page).to have_css(".login-image-box")
      expect(page).to have_css("img[src='#{ss_file1.url}']")
      expect(page).to have_css("img[src='#{ss_file2.url}']")
    end
  end

  context "when ad_links are not existed" do
    it do
      setting = Sys::Setting.new
      setting.save!
      setting.reload
      visit sns_login_path
      expect(page).to have_no_css(".login-image-box")

      visit sns_login_image_path
      expect(page).to have_no_css(".login-image-box")
    end
  end

  context "when there are no showable ad_links" do
    let(:ss_file1) do
      tmp_ss_file(
        basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:ss_file2) do
      tmp_ss_file(
        basename: "keyvisual-#{unique_id}.jpg", contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
    end

    it do
      setting = Sys::Setting.new
      setting.ad_links.build(url: unique_url, file_id: ss_file1.id, state: nil)
      setting.ad_links.build(url: unique_url, file_id: ss_file2.id, state: "hide")
      setting.save!
      setting.reload
      visit sns_login_path
      expect(page).to have_no_css(".login-image-box")

      visit sns_login_image_path
      expect(page).to have_no_css(".login-image-box")
    end
  end
end
