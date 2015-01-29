require 'spec_helper'

describe "voice_error_files" do
  subject(:site) { cms_site }
  subject(:index_path) { voice_error_files_path site.host }
  subject(:download_path) { voice_error_files_download_path site.host }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    subject(:item) { create(:voice_voice_file_with_error) }
    subject(:show_path) { voice_error_file_path site.host, item }
    subject(:delete_path) { delete_voice_error_file_path site.host, item }

    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#download" do
      item.id
      visit download_path
      expect(status_code).to eq 200
      expect(current_path).to eq download_path
    end
  end
end
