require 'spec_helper'

describe "mail_page_agents_parts_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :mail_page_part_page, filename: "node/part" }

  context "public" do
    let!(:item) { create :mail_page_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".mail_page-pages")
      expect(page).to have_selector(".mail_page-pages article")
    end
  end
end
