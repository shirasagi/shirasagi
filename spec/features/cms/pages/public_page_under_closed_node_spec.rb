require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create :cms_layout, site: site }
  let(:node) { create :category_node_page, cur_site: site, layout: layout.id, state: "closed" }
  let!(:item) { create :cms_page, cur_site: site, cur_node: node, layout: layout.id, basename: "index.html" }

  it do
    expect do
      visit item.full_url
    end.to raise_error(RuntimeError, "404")
  end
end
