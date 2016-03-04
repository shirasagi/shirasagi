require 'spec_helper'

describe "cms_agents_parts_tabs", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:part)   { create :cms_part_tabs }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".tabs")
    end
  end
end
