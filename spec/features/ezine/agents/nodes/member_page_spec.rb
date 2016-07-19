require 'spec_helper'

describe "ezine_agents_nodes_category_node", dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create :ezine_node_member_page, cur_site: site, layout_id: layout.id }

  context "with html ezine" do
    let(:name) { unique_id }
    let(:text) { unique_id }
    let(:html) { "<div><p>#{text}</p></div>" }

    before do
      create :ezine_page, cur_site: site, cur_node: node, layout_id: layout.id, name: name, html: html, text: text
    end

    it do
      visit node.full_url
      expect(page).to have_css("article header h2", text: name)

      click_on name
      expect(page).to have_css(".body > div > p", text: text)
    end
  end

  context "with text only ezine" do
    let(:name) { unique_id }
    let(:text) { unique_id }

    before do
      create :ezine_page, cur_site: site, cur_node: node, layout_id: layout.id, name: name, text: text
    end

    it do
      visit node.full_url
      expect(page).to have_css("article header h2", text: name)

      click_on name
      expect(page).to have_css(".body > p", text: text)
    end
  end
end
