require 'spec_helper'

describe "cms_agents_parts_crumb", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "with node" do
      let(:layout) { create_cms_layout [part] }
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
      let(:layout) { create_cms_layout [part] }
      let(:part) { create :cms_part_crumb }
      let(:category_1) { create :category_node_page, layout_id: layout.id, filename: "oshirase" }
      let(:category_2) { create :category_node_page, layout_id: layout.id, filename: "kurashi"}
      let(:category_3) { create :category_node_page, layout_id: layout.id, filename: "faq" }
      let(:node) { create :cms_node, layout_id: layout.id }
      let(:item) do
        create :cms_page, layout_id: layout.id, filename: "#{node.filename}/page.html",
        category_ids: [category_1.id, category_2.id, category_3.id],
        parent_crumb_urls: [category_1.url, category_2.url, category_3.url]
      end

      it "#index" do
        visit item.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
        expect(page).to have_link(category_1.name)
        expect(page).to have_link(category_2.name)
        expect(page).to have_link(category_3.name)
      end
    end
  end
end
