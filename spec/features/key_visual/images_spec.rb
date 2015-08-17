require 'spec_helper'

describe "key_visual_images" do
  let(:site) { cms_site }
  let(:node) { create_once :key_visual_node_image, name: "key_visual" }
  let(:item) { KeyVisual::Image.last }
  let(:index_path) { key_visual_images_path site.id, node }
  let(:new_path) { new_key_visual_image_path site.id, node }
  let(:show_path) { key_visual_image_path site.id, node, item }
  let(:edit_path) { edit_key_visual_image_path site.id, node, item }
  let(:delete_path) { delete_key_visual_image_path site.id, node, item }

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

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#invalid_new" do
      SS.config.replace_value_at(:env, :max_filesize_ext, { "png" => 1 })

      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[link_url]", with: "http://example.jp"
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_css("form#item-form")
    end

    it "#new" do
      SS.config.replace_value_at(:env, :max_filesize_ext, {})

      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[link_url]", with: "http://example.jp"
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
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
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
