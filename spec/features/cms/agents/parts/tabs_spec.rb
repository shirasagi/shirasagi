require 'spec_helper'

describe "cms_agents_parts_tabs", type: :feature, dbscope: :example do
  # default site
  let(:site) { cms_site }
  let(:layout) { create_cms_layout part, cur_site: site }
  let(:node) { create :cms_node, cur_site: site, layout_id: layout.id }
  let(:part) { create :cms_part_tabs, cur_site: site, conditions: [node2.filename, node3.filename, "#{site1.host}:#{site1_node1.filename}"] }
  let(:node2) { create :cms_node_node, cur_site: site }
  let!(:node2_page1) { create :cms_page, cur_site: site, cur_node: node2 }
  let(:node3) { create :cms_node_page, cur_site: site }
  let!(:node3_page1) { create :cms_page, cur_site: site, cur_node: node3 }

  # sub-site
  let(:site1) { create(:cms_site_subdir, parent: site) }
  let(:site1_node1) { create :cms_node_page, cur_site: site1, filename: node3.filename }
  let!(:site1_node1_page1) { create :cms_page, cur_site: site1, cur_node: site1_node1 }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".tabs")
      expect(page).to have_css("#cms-tab-1-0", text: node2_page1.name)
      expect(page).to have_css("#cms-tab-1-1", text: node3_page1.name)
      expect(page).to have_css("#cms-tab-1-2", text: site1_node1_page1.name)
    end
  end
end
