require 'spec_helper'

describe "cms_generate_pages", type: :feature, dbscope: :example, js: :true do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:node_1) { create :cms_node }
  let(:index_path) { node_conf_path site.id, node }
  let(:edit_path) { edit_node_conf_path site.id, node }
  let(:delete_path) { delete_node_conf_path site.id, node }
  context "Try Move Function" do 
    before { login_cms_user }
    
    it "#move" do 
      visit index_path
      click_link("移動する")
      wait_for_ajax
  
      expect(page).to have_css(".mod-cms-page-search")
      node_1.reload
  
      within(".mod-cms-page-search") do 
        click_link(I18n.t("cms.apis.nodes.index"))
      end
      wait_for_ajax
      expect(page).to have_css("tr[data-id='#{node_1.id}']")
      within("tr[data-id='#{node_1.id}']") do
        find("a.select-single-item").click
      end
      
      wait_for_ajax
  
      expect(page).to have_css(".send")
  
      within(".send") do 
        find("input[type='submit'][value='#{I18n.t("ss.buttons.move")}']").click
      end
      wait_for_ajax
  
      expect(page).to have_css("#cms-dialog")
  
      within("#cms-dialog") do 
        find("input[type='checkbox']").click
        find("input[type='submit'][value='#{I18n.t("ss.buttons.move")}']").click
      end
  
      wait_for_ajax
  
      expect(node.reload.filename).to include(node_1.filename)
    end
  end
end


