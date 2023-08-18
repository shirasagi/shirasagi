require 'spec_helper'

describe "cms_files", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:item) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'cms/file') }
  let(:index_path) { cms_files_path site.id }
  let(:new_path) { new_cms_file_path site.id }
  let(:show_path) { cms_file_path site.id, item }
  let(:edit_path) { edit_cms_file_path site.id, item }
  let(:delete_path) { delete_cms_file_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
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
end
