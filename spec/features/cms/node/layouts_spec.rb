require 'spec_helper'

describe "cms_node_layouts", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:item) { create :cms_layout, filename: "#{node.filename}/name" }
  let(:index_path)  { node_layouts_path site.id, node }
  let(:trash_path)  { "#{index_path}/trash" }
  let(:new_path)    { "#{index_path}/new" }
  let(:show_path)   { "#{index_path}/#{item.id}" }
  let(:edit_path)   { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }
  let(:soft_delete_path) { "#{index_path}/#{item.id}/soft_delete" }
  let(:undo_delete_path) { "#{index_path}/#{item.id}/undo_delete" }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button "保存"
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
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end

    it "#soft_delete" do
      visit soft_delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
      expect(page).to have_no_css("a.title", text: item.name)
      visit trash_path
      expect(page).to have_css("a.title", text: item.name)

      visit undo_delete_path
      within "form" do
        click_button "元に戻す"
      end
      expect(current_path).to eq index_path
      expect(page).to have_css("a.title", text: item.name)
      visit trash_path
      expect(page).to have_no_css("a.title", text: item.name)
    end
  end
end
