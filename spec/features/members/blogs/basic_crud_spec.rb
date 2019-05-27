require 'spec_helper'

describe "member_blogs", dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:layout) { create(:cms_layout, site: site, name: "blog") }
  let!(:blogs_node) { create_once :member_node_blog, filename: "blogs", name: "blogs", layout: layout }
  let!(:node) { create_once :member_node_blog_page, filename: "blogs/shirasagi-blog", name: "shirasagi-blog", layout: layout }
  let(:item) { create(:member_blog_page, cur_node: node) }
  let(:index_path) { member_blog_pages_path site.id, node }
  let(:new_path) { new_member_blog_page_path site.id, node }
  let(:show_path) { member_blog_page_path site.id, node, item }
  let(:edit_path) { edit_member_blog_page_path site.id, node, item }
  let(:delete_path) { delete_member_blog_page_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      expect(page.html).to include("本文を入力してください。")
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end
  end
end
