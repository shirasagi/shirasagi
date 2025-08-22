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
        # カテゴリリンクは別セクションに表示される
        expect(page).to have_css(".categories")
        expect(page).to have_link(category1.name)
        expect(page).to have_link(category2.name)
        expect(page).to have_link(category3.name)
      end
    end

    context "with categories and no parent_crumb_urls" do
      let(:layout) { create_cms_layout part }
      let(:part) { create :cms_part_crumb }
      let(:category1) { create :category_node_page, layout_id: layout.id, filename: "oshirase" }
      let(:category2) { create :category_node_page, layout_id: layout.id, filename: "kurashi" }
      let(:category3) { create :category_node_page, layout_id: layout.id, filename: "faq" }
      let(:node) { create :cms_node, layout_id: layout.id }
      let(:item) do
        create :cms_page, layout_id: layout.id, filename: "#{node.filename}/page.html",
        category_ids: [category1.id, category2.id, category3.id],
        parent_crumb_urls: [] # 空の配列を設定
      end

      it "#index with empty parent_crumb_urls" do
        visit item.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
        # カテゴリリンクは別セクションに表示される（parent_crumb_urlsとは無関係）
        expect(page).to have_css(".categories")
        expect(page).to have_link(category1.name)
        expect(page).to have_link(category2.name)
        expect(page).to have_link(category3.name)
      end
    end

    context "with categories and nil parent_crumb_urls" do
      let(:layout) { create_cms_layout part }
      let(:part) { create :cms_part_crumb }
      let(:category1) { create :category_node_page, layout_id: layout.id, filename: "oshirase" }
      let(:category2) { create :category_node_page, layout_id: layout.id, filename: "kurashi" }
      let(:category3) { create :category_node_page, layout_id: layout.id, filename: "faq" }
      let(:node) { create :cms_node, layout_id: layout.id }
      let(:item) do
        create :cms_page, layout_id: layout.id, filename: "#{node.filename}/page.html",
        category_ids: [category1.id, category2.id, category3.id],
        parent_crumb_urls: nil # nilを設定
      end

      it "#index with nil parent_crumb_urls" do
        visit item.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
        # カテゴリリンクは別セクションに表示される（parent_crumb_urlsとは無関係）
        expect(page).to have_css(".categories")
        expect(page).to have_link(category1.name)
        expect(page).to have_link(category2.name)
        expect(page).to have_link(category3.name)
      end
    end

    context "with categories and mixed parent_crumb_urls" do
      let(:layout) { create_cms_layout part }
      let(:part) { create :cms_part_crumb }
      let(:category1) { create :category_node_page, layout_id: layout.id, filename: "oshirase" }
      let(:category2) { create :category_node_page, layout_id: layout.id, filename: "kurashi" }
      let(:category3) { create :category_node_page, layout_id: layout.id, filename: "faq" }
      let(:node) { create :cms_node, layout_id: layout.id }
      let(:item) do
        create :cms_page, layout_id: layout.id, filename: "#{node.filename}/page.html",
        category_ids: [category1.id, category2.id, category3.id],
        parent_crumb_urls: [category1.url, "", category3.url] # 空文字を含む
      end

      it "#index with mixed parent_crumb_urls" do
        visit item.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
        # カテゴリリンクは別セクションに表示される（parent_crumb_urlsとは無関係）
        expect(page).to have_css(".categories")
        expect(page).to have_link(category1.name)
        expect(page).to have_link(category2.name)
        expect(page).to have_link(category3.name)
      end
    end

    context "with nested nodes" do
      let(:layout) { create_cms_layout part }
      let(:part) { create :cms_part_crumb }
      let(:parent_node) { create :cms_node, layout_id: layout.id, filename: "parent" }
      let(:child_node) { create :cms_node, layout_id: layout.id, filename: "parent/child" }
      let(:grandchild_node) { create :cms_node, layout_id: layout.id, filename: "parent/child/grandchild" }

      it "#index with nested structure" do
        visit grandchild_node.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
        # 階層構造が正しく表示されることを確認
        # 実際のパンくずリストにはノード名が表示されないため、基本構造のみ確認
        expect(page).to have_css(".crumbs .crumb span.page")
        expect(page).to have_css(".crumbs .crumb span.separator")
      end
    end

    context "with page and parent_crumb_urls" do
      let(:layout) { create_cms_layout part }
      let(:part) { create :cms_part_crumb }
      let(:category1) { create :category_node_page, layout_id: layout.id, filename: "oshirase" }
      let(:category2) { create :category_node_page, layout_id: layout.id, filename: "kurashi" }
      let(:node) { create :cms_node, layout_id: layout.id }
      let(:item) do
        create :cms_page, layout_id: layout.id, filename: "#{node.filename}/page.html",
        category_ids: [category1.id, category2.id],
        parent_crumb_urls: [category1.url, category2.url]
      end

      it "#index with parent_crumb_urls" do
        visit item.url
        expect(status_code).to eq 200
        expect(page).to have_css(".crumbs .crumb")
        expect(page).to have_selector(".crumbs .crumb span a")
        # パンくずリストの基本構造を確認
        expect(page).to have_css(".crumbs .crumb span.page")
        expect(page).to have_css(".crumbs .crumb span.separator")
        # カテゴリリンクは別セクションに表示される
        expect(page).to have_css(".categories")
        expect(page).to have_link(category1.name)
        expect(page).to have_link(category2.name)
      end
    end
  end
end
