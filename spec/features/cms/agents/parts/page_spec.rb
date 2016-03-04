require 'spec_helper'

describe "cms_agents_parts_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:layout) { create_cms_layout [item] }
  let(:item)   { create :cms_part_page }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
    end
  end
end
