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
      save_filename = node.filename

      visit index_path
      click_link(I18n.t("ss.links.move"))
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

      node.reload
      expect(node.parent.id).to eq node_1.id
      expect(node.filename).to eq "#{node_1.filename}/#{save_filename}"
    end

    it "when cancel" do
      visit index_path
      click_link(I18n.t("ss.links.move"))
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
        click_on I18n.t("ss.buttons.cancel")
      end

      expect(current_path).to eq move_node_conf_path(site: site, cid: node)
      expect(page).to have_css("form#item-form")
    end

    it "when slash('/') is given" do
      visit index_path
      click_link(I18n.t("ss.links.move"))
      wait_for_ajax

      within "form#item-form" do
        fill_in "destination", with: "#{node_1.filename}/#{unique_id}"
        click_on I18n.t("ss.buttons.move")
      end
      wait_for_error I18n.t("errors.messages.invalid_filename")
    end

    context "keep the same parent folder after move" do
      let(:node) { create :cms_node, cur_node: node_1 }
      let(:new_basename) { unique_id }

      it "#move" do
        expect(node.parent).to eq node_1

        visit index_path
        click_link(I18n.t("ss.links.move"))
        wait_for_ajax

        within "form#item-form" do
          fill_in "destination", with: new_basename
          click_on I18n.t("ss.buttons.move")
        end

        within("#cms-dialog") do
          find("input[type='checkbox']").click
          click_on I18n.t("ss.buttons.move")
        end
        wait_for_notice I18n.t("ss.notice.moved")

        node.reload
        expect(node.parent).to eq node_1
        expect(node.filename).to eq "#{node_1.filename}/#{new_basename}"
      end
    end
  end
end
