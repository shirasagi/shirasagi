require 'spec_helper'

describe "ezine_agents_nodes_category_node", dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :ezine_node_category_node, cur_site: site, layout_id: layout.id }
  let!(:node_member_page) { create :ezine_node_member_page, cur_site: site, cur_node: node, layout_id: layout.id }

  it do
    visit node.full_url
    expect(page).to have_css("article header h2", text: node_member_page.name)
  end
end
