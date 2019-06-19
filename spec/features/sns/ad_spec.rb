require 'spec_helper'

describe "login_ad", type: :feature, dbscope: :example, tmpdir: true do
  context "file exists" do
    let(:ss_file) { tmp_ss_link_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let(:ss_file2) { tmp_ss_link_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg") }
    it "display ad" do
      setting = Sys::Setting.new
      setting.file_ids = [ss_file.id, ss_file2.id]
      setting.save
      setting.reload
      visit sns_login_path
      expect(page).to have_css(".login-ad")
      expect(page).to have_css("img[src='#{ss_file.url}']")
      expect(page).to have_css("img[src='#{ss_file2.url}']")
    end
  end
  context "file not exists" do
    it "not display ad" do
      setting = Sys::Setting.new
      setting.save
      setting.reload
      visit sns_login_path
      expect(page).to have_no_css(".login-ad")
    end
  end
end
