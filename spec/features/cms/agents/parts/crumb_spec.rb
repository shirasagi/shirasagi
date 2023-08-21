require 'spec_helper'

describe "cms_agents_parts_crumb", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "with node" do
      let(:layout) { create_cms_layout part }
      let(:part) { create :cms_part_crumb }
      let(:node) { create :cms_node, layout_id: layout.id }

      it "#index" do
        visit node.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
      end
    end

    context "with categories" do
      let(:layout) { create_cms_layout part }
      let(:part) { create :cms_part_crumb }
      let(:category1) { create :category_node_page, layout_id: layout.id, filename: "oshirase" }
      let(:category2) { create :category_node_page, layout_id: layout.id, filename: "kurashi" }
      let(:category3) { create :category_node_page, layout_id: layout.id, filename: "faq" }
      let(:node) { create :cms_node, layout_id: layout.id }
      let(:item) do
        create :cms_page, layout_id: layout.id, filename: "#{node.filename}/page.html",
        category_ids: [category1.id, category2.id, category3.id],
        parent_crumb_urls: [category1.url, category2.url, category3.url]
      end

      it "#index" do
        visit item.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
        expect(page).to have_link(category1.name)
        expect(page).to have_link(category2.name)
        expect(page).to have_link(category3.name)
      end
    end
  end
end
