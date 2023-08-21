require 'spec_helper'

describe "sns_apis_user_files", type: :feature, dbscope: :example do
  let(:user) { ss_user }
  let(:item) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: user, model: 'ss/user_file') }
  let(:index_path) { sns_apis_user_files_path user.id }
  let(:new_path) { new_sns_apis_user_file_path user.id }
  let(:show_path) { sns_apis_user_file_path user.id, item }
  let(:edit_path) { edit_sns_apis_user_file_path user.id, item }
  let(:delete_path) { delete_sns_apis_user_file_path user.id, item }
  let(:select_path) { select_sns_apis_user_file_path user.id, item }

  context "with auth" do
    before { login_ss_user }

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
      visit select_path
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
end
