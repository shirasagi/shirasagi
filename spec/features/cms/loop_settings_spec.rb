require 'spec_helper'

describe "cms_loop_settings", dbscope: :example, type: :feature do
  let(:site) { cms_site }
  let(:item) { create(:cms_loop_setting, site: site) }
  let(:index_path) { cms_loop_settings_path site.id }
  let(:new_path) { new_cms_loop_setting_path site.id }
  let(:show_path) { cms_loop_setting_path site.id, item }
  let(:edit_path) { edit_cms_loop_setting_path site.id, item }
  let(:delete_path) { delete_cms_loop_setting_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#show" do
      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#edit" do
      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#delete" do
      it do
        visit delete_path
        within "form" do
          click_button "削除"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end
  end
end
