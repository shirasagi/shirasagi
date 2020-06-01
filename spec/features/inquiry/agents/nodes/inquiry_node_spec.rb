require 'spec_helper'

describe "inquiry_agents_nodes_node", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) do
    create(
      :inquiry_node_node,
      cur_site: site,
      layout_id: layout.id)
  end
  let!(:child_node1) do
    create(
      :inquiry_node_form,
      cur_site: site,
      cur_node: node,
      layout_id: layout.id)
  end
  let!(:child_node2) do
    create(
      :inquiry_node_form,
      cur_site: site,
      cur_node: node,
      layout_id: layout.id)
  end
  let!(:child_node3) do
    create(
      :inquiry_node_form,
      cur_site: site,
      cur_node: node,
      layout_id: layout.id)
  end

  context "upper_html lower_html" do
    it do
      visit node.full_url

      expect(page).to have_content(node.upper_html)
      expect(page).to have_content(child_node1.name)
      expect(page).to have_content(child_node2.name)
      expect(page).to have_content(child_node3.name)
      expect(page).to have_content(node.lower_html)
    end
  end

  context "loop_html" do
    let(:loop_html) { '<div class="#{class}"><header><h2>#{name}</h2></header></div>' }
    let(:node) do
      create(
        :inquiry_node_node,
        cur_site: site,
        layout_id: layout.id,
        loop_html: loop_html)
    end
    it do
      visit node.full_url

      expect(page).to have_content(node.upper_html)
      expect(page).to have_css("h2", text: child_node1.name)
      expect(page).to have_css("h2", text: child_node2.name)
      expect(page).to have_css("h2", text: child_node3.name)
      expect(page).to have_content(node.lower_html)
    end
  end

  context "liquid" do
    let(:node) do
      create(
        :inquiry_node_node,
        cur_site: site,
        layout_id: layout.id,
        loop_format: "liquid")
    end

    it do
      visit node.full_url

      expect(page).not_to have_content(node.upper_html)
      expect(page).to have_css("a", text: child_node1.name)
      expect(page).to have_css("a", text: child_node2.name)
      expect(page).to have_css("a", text: child_node3.name)
      expect(page).not_to have_content(node.lower_html)
    end
  end
end
