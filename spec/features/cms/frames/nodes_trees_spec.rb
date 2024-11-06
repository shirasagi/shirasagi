require 'spec_helper'

describe "cms_frames_nodes_trees", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node1) { create :article_node_page, cur_site: site }
  let!(:node2) { create :category_node_node, cur_site: site }
  let!(:node2_1) { create :category_node_node, cur_site: site, cur_node: node2 }
  let!(:node2_2) { create :category_node_node, cur_site: site, cur_node: node2 }
  let!(:node2_1_1) { create :category_node_page, cur_site: site, cur_node: node2_1 }
  let!(:node2_1_2) { create :category_node_page, cur_site: site, cur_node: node2_1 }
  let!(:node2_2_1) { create :category_node_page, cur_site: site, cur_node: node2_2 }
  let!(:node2_2_2) { create :category_node_page, cur_site: site, cur_node: node2_2 }

  before { login_cms_user }

  context "without current node" do
    it do
      visit cms_nodes_path(site: site)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      wait_for_tree_render "#cms-nodes-tree-frame"
      within "#cms-nodes-tree-frame" do
        expect(page).to have_css(".ss-tree[role='tree']", count: 1)
        expect(page).to have_css(".ss-tree-item[role='treeitem']", count: 8)
        expect(page).to have_css(".ss-tree-item.no-children[role='treeitem']", count: 5)
        expect(page).to have_css(".ss-tree-subtree-wrap", count: 3)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node1.id}']", text: node1.name)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2.id}']", text: node2.name)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1.id}']", text: node2_1.name)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2.id}']", text: node2_2.name)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_1.id}']", text: node2_1_1.name)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_2.id}']", text: node2_1_2.name)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_1.id}']", text: node2_2_1.name)
        expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_2.id}']", text: node2_2_2.name)
      end
    end
  end

  context "with node2" do
    it do
      visit category_nodes_path(site: site, cid: node2)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      wait_for_tree_render "#cms-nodes-tree-frame"
      within "#cms-nodes-tree-frame" do
        expect(page).to have_css(".ss-tree[role='tree']", count: 1)
        expect(page).to have_css(".ss-tree-item[role='treeitem']", count: 8)
        # expect(page).to have_css(".ss-tree-item.no-children[role='treeitem']", count: 5)
        # expect(page).to have_css(".ss-tree-subtree-wrap", count: 3)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node1.id}']", text: node1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2.id}']", text: node2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1.id}']", text: node2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2.id}']", text: node2_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_1.id}']", text: node2_1_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_2.id}']", text: node2_1_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_1.id}']", text: node2_2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_2.id}']", text: node2_2_2.name)

        expect(page).to have_css(".ss-tree-item.is-current .ss-tree-item-link[data-node-id='#{node2.id}']", text: node2.name)

        # 自フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_truthy
        end
        # 子孫フォルダーは展開されていない
        first(".ss-tree-item-link[data-node-id='#{node2_1.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_falsey
        end
        first(".ss-tree-item-link[data-node-id='#{node2_2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_falsey
        end
      end
    end
  end

  context "with node2_1" do
    it do
      visit category_nodes_path(site: site, cid: node2_1)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      wait_for_tree_render "#cms-nodes-tree-frame"
      within "#cms-nodes-tree-frame" do
        expect(page).to have_css(".ss-tree[role='tree']", count: 1)
        expect(page).to have_css(".ss-tree-item[role='treeitem']", count: 8)
        # expect(page).to have_css(".ss-tree-item.no-children[role='treeitem']", count: 5)
        # expect(page).to have_css(".ss-tree-subtree-wrap", count: 3)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node1.id}']", text: node1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2.id}']", text: node2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1.id}']", text: node2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2.id}']", text: node2_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_1.id}']", text: node2_1_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_2.id}']", text: node2_1_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_1.id}']", text: node2_2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_2.id}']", text: node2_2_2.name)

        expect(page).to have_css(".is-current .ss-tree-item-link[data-node-id='#{node2_1.id}']", text: node2_1.name)

        # 親フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_truthy
        end
        # 自フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2_1.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_truthy
        end
        # 兄弟フォルダーは展開されていない
        first(".ss-tree-item-link[data-node-id='#{node2_2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_falsey
        end
      end
    end
  end

  context "with node2_2_2" do
    it do
      visit category_pages_path(site: site, cid: node2_2_2)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      wait_for_tree_render "#cms-nodes-tree-frame"
      within "#cms-nodes-tree-frame" do
        expect(page).to have_css(".ss-tree[role='tree']", count: 1)
        expect(page).to have_css(".ss-tree-item[role='treeitem']", count: 8)
        # expect(page).to have_css(".ss-tree-item.no-children[role='treeitem']", count: 5)
        # expect(page).to have_css(".ss-tree-subtree-wrap", count: 3)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node1.id}']", text: node1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2.id}']", text: node2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1.id}']", text: node2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2.id}']", text: node2_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_1.id}']", text: node2_1_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_2.id}']", text: node2_1_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_1.id}']", text: node2_2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_2.id}']", text: node2_2_2.name)

        expect(page).to have_css(".is-current .ss-tree-item-link[data-node-id='#{node2_2_2.id}']", text: node2_2_2.name)

        # 親フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_truthy
        end
        # 自フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2_1.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_falsey
        end
        # 親フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2_2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_truthy
        end
      end
    end
  end

  context "with node2_2_2 through module change" do
    it do
      visit garbage_categories_path(site: site, cid: node2_2_2)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      wait_for_tree_render "#cms-nodes-tree-frame"
      within "#cms-nodes-tree-frame" do
        expect(page).to have_css(".ss-tree[role='tree']", count: 1)
        expect(page).to have_css(".ss-tree-item[role='treeitem']", count: 8)
        # expect(page).to have_css(".ss-tree-item.no-children[role='treeitem']", count: 5)
        # expect(page).to have_css(".ss-tree-subtree-wrap", count: 3)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node1.id}']", text: node1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2.id}']", text: node2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1.id}']", text: node2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2.id}']", text: node2_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_1.id}']", text: node2_1_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_1_2.id}']", text: node2_1_2.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_1.id}']", text: node2_2_1.name)
        # expect(page).to have_css(".ss-tree-item-link[data-node-id='#{node2_2_2.id}']", text: node2_2_2.name)

        expect(page).to have_css(".is-current .ss-tree-item-link[data-node-id='#{node2_2_2.id}']", text: node2_2_2.name)

        # 親フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_truthy
        end
        # 自フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2_1.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_falsey
        end
        # 親フォルダーは展開されている
        first(".ss-tree-item-link[data-node-id='#{node2_2.id}']").tap do |el|
          wrap_el = el.evaluate_script("this.closest('.ss-tree-subtree-wrap')")
          expect(wrap_el.evaluate_script('this.open')).to be_truthy
        end
      end
    end
  end
end
