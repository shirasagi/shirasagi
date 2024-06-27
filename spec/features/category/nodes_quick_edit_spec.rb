require 'spec_helper'

describe "category_nodes_base", type: :feature, dbscope: :example, js: :true do 
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:index_path)  { category_nodes_path site.id, node }
  let(:item) { create :category_node_base, name: "sample", filename: "#{node.filename}/name", order: 10, site: site }
  let(:quick_edit_path) { quick_edit_category_nodes_path site.id, node }

  context "check quck edit" do
    before { login_cms_user }

    it "quick edit" do
      item.save!
      item.reload

      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css("a", text: "tune")
      click_link "tune"
      wait_for_ajax
      expect(page).to have_css(".quick-edit-grid")

      within ".quick-edit-grid" do 
        expect(page).to have_css("tr[data-id='#{item.id}']")

        within "tr[data-id='#{item.id}']" do 
          fill_in "name", with: "quick edit name"
          page.execute_script("document.querySelector('input[name=\"name\"]').blur()")

          fill_in "filename", with: "#{node.filename}/quick_edit_filename"
          page.execute_script("document.querySelector('input[name=\"filename\"]').blur()")

          fill_in "order", with: "11"
          page.execute_script("document.querySelector('input[name=\"order\"]').blur()")

          expect(page).to have_content(I18n.t("ss.notice.saved"))
        end
      end

      visit quick_edit_path
      expect(page).to have_css(".quick-edit-grid")
      within ".quick-edit-grid" do 
        expect(page).to have_css("tr[data-id='#{item.id}']")
        within "tr[data-id='#{item.id}']" do 
          expect(find("input[name='name']").value).to eq "quick edit name"
          expect(find("input[name='filename']").value).to eq "#{node.filename}/quick_edit_filename"
          expect(find("input[name='order']").value).to eq "11"
        end
      end    
    end
  end
end