require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node_node, filename: "node" }
  let(:sub_node) { create :cms_node_archive, filename: "node/sub_node" }
  let(:item) { create :cms_page, cur_node: node, basename: 'page' }
  let(:sub_item) { create :cms_page, cur_node: sub_node, basename: 'page' }
  let!(:member_login_node) { create :member_node_login }
  let(:show_path) { node_page_path site.id, node.id, item.id }
  let(:sub_show_path) { node_page_path site.id, sub_node.id, sub_item.id }

  context "with for member state" do
    before do
      node.for_member_state = 'enabled'
      node.save!
      login_cms_user
    end

    it "public" do
      visit show_path
      expect(status_code).to eq 200

      click_link item.full_url
      expect(status_code).to eq 200
      expect(current_path).to eq "#{member_login_node.url}login.html"
    end

    it "preview" do
      visit show_path
      expect(status_code).to eq 200

      click_link I18n.t("ss.links.pc_preview")
      expect(status_code).to eq 200
      expect(current_path).to eq cms_preview_path(site.id, path: item.preview_path)
    end

    it "sub page public" do
      visit sub_show_path
      expect(status_code).to eq 200

      click_link sub_item.full_url
      expect(status_code).to eq 200
      expect(current_path).to eq "#{member_login_node.url}login.html"
    end

    it "sub page preview" do
      visit sub_show_path
      expect(status_code).to eq 200

      click_link I18n.t("ss.links.pc_preview")
      expect(status_code).to eq 200
      expect(current_path).to eq cms_preview_path(site.id, path: sub_item.preview_path)
    end
  end
end
