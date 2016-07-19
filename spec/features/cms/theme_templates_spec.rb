require 'spec_helper'

describe "cms_theme_templates", dbscope: :example, type: :feature do
  let(:site) { cms_site }
  let(:item) { create(:cms_theme_template, site: site) }
  let(:index_path) { cms_theme_templates_path site.id }
  let(:new_path) { new_cms_theme_template_path site.id }
  let(:show_path) { cms_theme_template_path site.id, item }
  let(:edit_path) { edit_cms_theme_template_path site.id, item }
  let(:delete_path) { delete_cms_theme_template_path site.id, item }

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
          fill_in "item[class_name]", with: "class-#{unique_id}"
          fill_in "item[css_path]", with: "/css/black.css"
          fill_in "item[order]", with: 10
          select "公開", from: "item_state"

          select "有効", from: "item_high_contrast_mode"
          fill_in "item[font_color]", with: "html-#{unique_id}"
          fill_in "item[background_color]", with: "html-#{unique_id}"

          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
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
          select "無効", from: "item_high_contrast_mode"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_css("form#item-form")
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
