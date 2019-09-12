require 'spec_helper'

describe "voice_files", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:index_path) { voice_files_path site.id }
  subject(:download_path) { download_voice_files_path site.id }

  context "with auth" do
    subject(:item) { create(:voice_voice_file) }
    subject(:show_path) { voice_file_path site.id, item }
    subject(:delete_path) { delete_voice_file_path site.id, item }

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
        click_button I18n.t('ss.buttons.delete')
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
