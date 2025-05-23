require 'spec_helper'

describe "facility_apis_temp_files", type: :feature, dbscope: :example do
  let(:site) { cms_site.set(multibyte_filename_state: 'disabled') }
  let(:item) do
    tmp_ss_file(
      Cms::File, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: Cms::File::FILE_MODEL)
  end
  let(:index_path) { cms_apis_files_path site.id, '-' }
  let(:new_path) { new_cms_apis_file_path site.id, '-' }
  let(:show_path) { cms_apis_file_path site.id, '-', item }
  let(:edit_path) { edit_cms_apis_file_path site.id, '-', item }
  let(:delete_path) { delete_cms_apis_file_path site.id, '-', item }
  let(:select_path) { select_cms_apis_file_path site.id, '-', item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "#ajax-form" do
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

    it "#select" do
      visit edit_path
      expect(status_code).to eq 200
    end

    it "#edit" do
      visit edit_path
      within "#ajax-form" do
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

  context "when filename is use multibyte character" do
    before { login_cms_user }
    it "#new" do
      visit new_path
      within "#ajax-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/ロゴ.png"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#errorExplanation')
    end
  end
end
