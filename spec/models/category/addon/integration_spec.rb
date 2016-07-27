require 'spec_helper'

describe Category::Addon::Integration, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  context "validation error" do
    #
  end

  context "1 depth category nodes" do
    before do
      Fs.rm_rf "#{site.path}/integration"
      Fs.rm_rf "#{site.path}/master"
      Fs.rm_rf "#{site.path}/partial"
    end
    # mater contents
    let!(:master_node) { create :category_node_node, site: site, user: user, filename: "master", name: "master" }

    let!(:master_child_node_A) { create :category_node_node, site: site, user: user, filename: "master/A", name: "master-A" }
    let!(:master_child_node_B) { create :category_node_page, site: site, user: user, filename: "master/B", name: "master-B" }
    let!(:master_child_node_C) { create :category_node_page, site: site, user: user, filename: "master/A/C", name: "master-A-C" }

    let!(:master_child_page_A) { create :cms_page, site: site, user: user, filename: "master/index.html", name: "master-index" }
    let!(:master_child_page_B) { create :article_page, site: site, user: user, filename: "master/page.html", name: "master-page" }
    let!(:master_child_page_C) { create :article_page, site: site, user: user, filename: "master/A/page.html", name: "master-page" }

    let!(:master_child_part_A) { create :cms_part, site: site, user: user, filename: "master/recent.part.html", name: "master-recent" }
    let!(:master_child_layout_A) { create :cms_layout, site: site, user: user, filename: "master/top.layout.html", name: "master-top" }

    # partial contents
    let!(:partial_node) { create :category_node_node, site: site, user: user, filename: "partial", name: "partial" }
    let!(:partial_child_node_D) { create :category_node_node, site: site, user: user, filename: "partial/D", name: "partial-D" }
    let!(:partial_child_node_E) { create :category_node_page, site: site, user: user, filename: "partial/E", name: "partial-E" }
    let!(:partial_child_node_F) { create :article_node_page, site: site, user: user, filename: "partial/D/F", name: "partial-D-F", category_ids: [partial_node.id] }

    let!(:partial_child_page_D) { create :article_page, site: site, user: user, filename: "partial/page2.html", name: "partial-page2", category_ids: [partial_node.id] }
    let!(:partial_child_page_E) { create :cms_page, site: site, user: user, filename: "partial/E/index.html", name: "partial-E-index" }
    let!(:partial_child_page_F) { create :cms_page, site: site, user: user, filename: "partial/D/F/index.html", name: "partial-D-F-index" }

    let!(:partial_child_part_B) { create :cms_part, site: site, user: user, filename: "partial/header.part.html", name: "partial-header" }
    let!(:partial_child_layout_B) { create :cms_layout, site: site, user: user, filename: "partial/one.layout.html", name: "partial-one" }

    let!(:expected_integrated_nodes) do
      [
        ["master", "master", 1],
        ["master-A", "master/A", 2],
        ["master-B", "master/B", 2],
        ["master-A-C", "master/A/C", 3],
        ["partial-D", "master/D", 2],
        ["partial-E", "master/E", 2],
        ["partial-D-F", "master/D/F", 3],
      ]
    end

    let!(:expected_integrated_pages) do
      [
        ["master-index", "master/index.html", 2],
        ["master-page", "master/page.html", 2],
        ["master-page", "master/A/page.html", 3],
        ["partial-page2", "master/page2.html", 2],
        ["partial-E-index", "master/E/index.html", 3],
        ["partial-D-F-index", "master/D/F/index.html", 4],
      ]
    end

    let!(:expected_integrated_layouts) do
      [
        ["master-top", "master/top.layout.html", 2],
        ["partial-one", "master/one.layout.html", 2],
      ]
    end

    let!(:expected_integrated_parts) do
      [
        ["master-recent", "master/recent.part.html", 2],
        ["partial-header", "master/header.part.html", 2],
      ]
    end

    it "#integrate" do
      master_node.in_partial_id = partial_node.id
      master_node.cur_user = user
      master_node.cur_node = master_node
      master_node.cur_site = site

      # do integrate
      expect(master_node.integrate).to be_truthy, "validation error\n#{master_node.errors.full_messages.join("\n")}"

      # compare contents
      integrated_nodes = Cms::Node.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_pages = Cms::Page.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_layouts = Cms::Layout.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_parts = Cms::Part.site(site).map { |item| [item.name, item.filename, item.depth] }

      expect(integrated_nodes).to match_array expected_integrated_nodes
      expect(integrated_pages).to match_array expected_integrated_pages
      expect(integrated_layouts).to match_array expected_integrated_layouts
      expect(integrated_parts).to match_array expected_integrated_parts

      # check embeds ids
      article_node = Article::Node::Page.site(site).where(filename: "master/D/F").first
      article_page = Article::Page.site(site).where(filename: "master/page2.html").first

      expect(article_node.category_ids.include?(master_node.id)).to be_truthy
      expect(article_page.category_ids.include?(master_node.id)).to be_truthy
    end
  end

  context "2 depth category nodes" do
    before do
      Fs.rm_rf "#{site.path}/integration"
      Fs.rm_rf "#{site.path}/master"
      Fs.rm_rf "#{site.path}/partial"
    end
    let!(:root_node) { create :cms_node_node, site: site, user: user, filename: "integration", name: "integration" }

    # mater contents
    let!(:master_node) { create :category_node_node, site: site, user: user, filename: "integration/master", name: "master" }

    let!(:master_child_node_A) { create :category_node_node, site: site, user: user, filename: "integration/master/A", name: "master-A" }
    let!(:master_child_node_B) { create :category_node_page, site: site, user: user, filename: "integration/master/B", name: "master-B" }
    let!(:master_child_node_C) { create :category_node_page, site: site, user: user, filename: "integration/master/A/C", name: "master-A-C" }

    let!(:master_child_page_A) { create :cms_page, site: site, user: user, filename: "integration/master/index.html", name: "master-index" }
    let!(:master_child_page_B) { create :article_page, site: site, user: user, filename: "integration/master/page.html", name: "master-page" }
    let!(:master_child_page_C) { create :article_page, site: site, user: user, filename: "integration/master/A/page.html", name: "master-page" }

    let!(:master_child_part_A) { create :cms_part, site: site, user: user, filename: "integration/master/recent.part.html", name: "master-recent" }
    let!(:master_child_layout_A) { create :cms_layout, site: site, user: user, filename: "integration/master/top.layout.html", name: "master-top" }

    # partial contents
    let!(:partial_node) { create :category_node_node, site: site, user: user, filename: "integration/partial", name: "partial" }
    let!(:partial_child_node_D) { create :category_node_node, site: site, user: user, filename: "integration/partial/D", name: "partial-D" }
    let!(:partial_child_node_E) { create :category_node_page, site: site, user: user, filename: "integration/partial/E", name: "partial-E" }
    let!(:partial_child_node_F) { create :article_node_page, site: site, user: user, filename: "integration/partial/D/F", name: "partial-D-F", category_ids: [partial_node.id] }

    let!(:partial_child_page_D) { create :article_page, site: site, user: user, filename: "integration/partial/page2.html", name: "partial-page2", category_ids: [partial_node.id] }
    let!(:partial_child_page_E) { create :cms_page, site: site, user: user, filename: "integration/partial/E/index.html", name: "partial-E-index" }
    let!(:partial_child_page_F) { create :cms_page, site: site, user: user, filename: "integration/partial/D/F/index.html", name: "partial-D-F-index" }

    let!(:partial_child_part_B) { create :cms_part, site: site, user: user, filename: "integration/partial/header.part.html", name: "partial-header" }
    let!(:partial_child_layout_B) { create :cms_layout, site: site, user: user, filename: "integration/partial/one.layout.html", name: "partial-one" }

    let!(:expected_integrated_nodes) do
      [
        ["integration", "integration", 1],
        ["master", "integration/master", 2],
        ["master-A", "integration/master/A", 3],
        ["master-B", "integration/master/B", 3],
        ["master-A-C", "integration/master/A/C", 4],
        ["partial-D", "integration/master/D", 3],
        ["partial-E", "integration/master/E", 3],
        ["partial-D-F", "integration/master/D/F", 4],
      ]
    end

    let!(:expected_integrated_pages) do
      [
        ["master-index", "integration/master/index.html", 3],
        ["master-page", "integration/master/page.html", 3],
        ["master-page", "integration/master/A/page.html", 4],
        ["partial-page2", "integration/master/page2.html", 3],
        ["partial-E-index", "integration/master/E/index.html", 4],
        ["partial-D-F-index", "integration/master/D/F/index.html", 5],
      ]
    end

    let!(:expected_integrated_layouts) do
      [
        ["master-top", "integration/master/top.layout.html", 3],
        ["partial-one", "integration/master/one.layout.html", 3],
      ]
    end

    let!(:expected_integrated_parts) do
      [
        ["master-recent", "integration/master/recent.part.html", 3],
        ["partial-header", "integration/master/header.part.html", 3],
      ]
    end

    it "#integrate" do
      master_node.in_partial_id = partial_node.id
      master_node.cur_user = user
      master_node.cur_node = master_node
      master_node.cur_site = site

      # do integrate
      expect(master_node.integrate).to be_truthy, "validation error\n#{master_node.errors.full_messages.join("\n")}"

      # compare contents
      integrated_nodes = Cms::Node.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_pages = Cms::Page.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_layouts = Cms::Layout.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_parts = Cms::Part.site(site).map { |item| [item.name, item.filename, item.depth] }

      expect(integrated_nodes).to match_array expected_integrated_nodes
      expect(integrated_pages).to match_array expected_integrated_pages
      expect(integrated_layouts).to match_array expected_integrated_layouts
      expect(integrated_parts).to match_array expected_integrated_parts

      # check embeds ids
      article_node = Article::Node::Page.site(site).where(filename: "integration/master/D/F").first
      article_page = Article::Page.site(site).where(filename: "integration/master/page2.html").first

      expect(article_node.category_ids.include?(master_node.id)).to be_truthy
      expect(article_page.category_ids.include?(master_node.id)).to be_truthy
    end
  end

  context "different depth category nodes" do
    before do
      Fs.rm_rf "#{site.path}/integration"
      Fs.rm_rf "#{site.path}/master"
      Fs.rm_rf "#{site.path}/partial"
    end
    let!(:root_node) { create :cms_node_node, site: site, user: user, filename: "integration", name: "integration" }
    let!(:root_under_node) { create :cms_node_node, site: site, user: user, filename: "integration/under", name: "under" }

    # mater contents
    let!(:master_node) { create :category_node_node, site: site, user: user, filename: "integration/under/master", name: "master" }

    let!(:master_child_node_A) { create :category_node_node, site: site, user: user, filename: "integration/under/master/A", name: "master-A" }
    let!(:master_child_node_B) { create :category_node_page, site: site, user: user, filename: "integration/under/master/B", name: "master-B" }
    let!(:master_child_node_C) { create :category_node_page, site: site, user: user, filename: "integration/under/master/A/C", name: "master-A-C" }

    let!(:master_child_page_A) { create :cms_page, site: site, user: user, filename: "integration/under/master/index.html", name: "master-index" }
    let!(:master_child_page_B) { create :article_page, site: site, user: user, filename: "integration/under/master/page.html", name: "master-page" }
    let!(:master_child_page_C) { create :article_page, site: site, user: user, filename: "integration/under/master/A/page.html", name: "master-page" }

    let!(:master_child_part_A) { create :cms_part, site: site, user: user, filename: "integration/under/master/recent.part.html", name: "master-recent" }
    let!(:master_child_layout_A) { create :cms_layout, site: site, user: user, filename: "integration/under/master/top.layout.html", name: "master-top" }

    # partial contents
    let!(:partial_node) { create :category_node_node, site: site, user: user, filename: "integration/partial", name: "partial" }
    let!(:partial_child_node_D) { create :category_node_node, site: site, user: user, filename: "integration/partial/D", name: "partial-D" }
    let!(:partial_child_node_E) { create :category_node_page, site: site, user: user, filename: "integration/partial/E", name: "partial-E" }
    let!(:partial_child_node_F) { create :article_node_page, site: site, user: user, filename: "integration/partial/D/F", name: "partial-D-F", category_ids: [partial_node.id] }

    let!(:partial_child_page_D) { create :article_page, site: site, user: user, filename: "integration/partial/page2.html", name: "partial-page2", category_ids: [partial_node.id] }
    let!(:partial_child_page_E) { create :cms_page, site: site, user: user, filename: "integration/partial/E/index.html", name: "partial-E-index" }
    let!(:partial_child_page_F) { create :cms_page, site: site, user: user, filename: "integration/partial/D/F/index.html", name: "partial-D-F-index" }

    let!(:partial_child_part_B) { create :cms_part, site: site, user: user, filename: "integration/partial/header.part.html", name: "partial-header" }
    let!(:partial_child_layout_B) { create :cms_layout, site: site, user: user, filename: "integration/partial/one.layout.html", name: "partial-one" }

    let!(:expected_integrated_nodes) do
      [
        ["integration", "integration", 1],
        ["under", "integration/under", 2],
        ["master", "integration/under/master", 3],
        ["master-A", "integration/under/master/A", 4],
        ["master-B", "integration/under/master/B", 4],
        ["master-A-C", "integration/under/master/A/C", 5],
        ["partial-D", "integration/under/master/D", 4],
        ["partial-E", "integration/under/master/E", 4],
        ["partial-D-F", "integration/under/master/D/F", 5],
      ]
    end

    let!(:expected_integrated_pages) do
      [
        ["master-index", "integration/under/master/index.html", 4],
        ["master-page", "integration/under/master/page.html", 4],
        ["master-page", "integration/under/master/A/page.html", 5],
        ["partial-page2", "integration/under/master/page2.html", 4],
        ["partial-E-index", "integration/under/master/E/index.html", 5],
        ["partial-D-F-index", "integration/under/master/D/F/index.html", 6],
      ]
    end

    let!(:expected_integrated_layouts) do
      [
        ["master-top", "integration/under/master/top.layout.html", 4],
        ["partial-one", "integration/under/master/one.layout.html", 4],
      ]
    end

    let!(:expected_integrated_parts) do
      [
        ["master-recent", "integration/under/master/recent.part.html", 4],
        ["partial-header", "integration/under/master/header.part.html", 4],
      ]
    end

    it "#integrate" do
      master_node.in_partial_id = partial_node.id
      master_node.cur_user = user
      master_node.cur_node = master_node
      master_node.cur_site = site

      # do integrate
      expect(master_node.integrate).to be_truthy, "validation error\n#{master_node.errors.full_messages.join("\n")}"

      # compare contents
      integrated_nodes = Cms::Node.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_pages = Cms::Page.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_layouts = Cms::Layout.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_parts = Cms::Part.site(site).map { |item| [item.name, item.filename, item.depth] }

      expect(integrated_nodes).to match_array expected_integrated_nodes
      expect(integrated_pages).to match_array expected_integrated_pages
      expect(integrated_layouts).to match_array expected_integrated_layouts
      expect(integrated_parts).to match_array expected_integrated_parts

      # check embeds ids
      article_node = Article::Node::Page.site(site).where(filename: "integration/under/master/D/F").first
      article_page = Article::Page.site(site).where(filename: "integration/under/master/page2.html").first

      expect(article_node.category_ids.include?(master_node.id)).to be_truthy
      expect(article_page.category_ids.include?(master_node.id)).to be_truthy
    end
  end

  context "partial is master's child node" do
    before do
      Fs.rm_rf "#{site.path}/integration"
      Fs.rm_rf "#{site.path}/master"
      Fs.rm_rf "#{site.path}/partial"
    end
    let!(:root_node) { create :cms_node_node, site: site, user: user, filename: "integration", name: "integration" }

    # mater contents
    let!(:master_node) { create :category_node_node, site: site, user: user, filename: "integration/master", name: "master" }

    let!(:master_child_node_A) { create :category_node_node, site: site, user: user, filename: "integration/master/A", name: "master-A" }
    let!(:master_child_node_B) { create :category_node_page, site: site, user: user, filename: "integration/master/B", name: "master-B" }
    let!(:master_child_node_C) { create :category_node_page, site: site, user: user, filename: "integration/master/A/C", name: "master-A-C" }

    let!(:master_child_page_A) { create :cms_page, site: site, user: user, filename: "integration/master/index.html", name: "master-index" }
    let!(:master_child_page_B) { create :article_page, site: site, user: user, filename: "integration/master/page.html", name: "master-page" }
    let!(:master_child_page_C) { create :article_page, site: site, user: user, filename: "integration/master/A/page.html", name: "master-page" }

    let!(:master_child_part_A) { create :cms_part, site: site, user: user, filename: "integration/master/recent.part.html", name: "master-recent" }
    let!(:master_child_layout_A) { create :cms_layout, site: site, user: user, filename: "integration/master/top.layout.html", name: "master-top" }

    # partial contents
    let!(:partial_node) { create :category_node_node, site: site, user: user, filename: "integration/master/partial", name: "partial" }
    let!(:partial_child_node_D) { create :category_node_node, site: site, user: user, filename: "integration/master/partial/D", name: "partial-D" }
    let!(:partial_child_node_E) { create :category_node_page, site: site, user: user, filename: "integration/master/partial/E", name: "partial-E" }
    let!(:partial_child_node_F) { create :article_node_page, site: site, user: user, filename: "integration/master/partial/D/F", name: "partial-D-F", category_ids: [partial_node.id] }

    let!(:partial_child_page_D) { create :article_page, site: site, user: user, filename: "integration/master/partial/page2.html", name: "partial-page2", category_ids: [partial_node.id] }
    let!(:partial_child_page_E) { create :cms_page, site: site, user: user, filename: "integration/master/partial/E/index.html", name: "partial-E-index" }
    let!(:partial_child_page_F) { create :cms_page, site: site, user: user, filename: "integration/master/partial/D/F/index.html", name: "partial-D-F-index" }

    let!(:partial_child_part_B) { create :cms_part, site: site, user: user, filename: "integration/master/partial/header.part.html", name: "partial-header" }
    let!(:partial_child_layout_B) { create :cms_layout, site: site, user: user, filename: "integration/master/partial/one.layout.html", name: "partial-one" }

    let!(:expected_integrated_nodes) do
      [
        ["integration", "integration", 1],
        ["master", "integration/master", 2],
        ["master-A", "integration/master/A", 3],
        ["master-B", "integration/master/B", 3],
        ["master-A-C", "integration/master/A/C", 4],
        ["partial-D", "integration/master/D", 3],
        ["partial-E", "integration/master/E", 3],
        ["partial-D-F", "integration/master/D/F", 4],
      ]
    end

    let!(:expected_integrated_pages) do
      [
        ["master-index", "integration/master/index.html", 3],
        ["master-page", "integration/master/page.html", 3],
        ["master-page", "integration/master/A/page.html", 4],
        ["partial-page2", "integration/master/page2.html", 3],
        ["partial-E-index", "integration/master/E/index.html", 4],
        ["partial-D-F-index", "integration/master/D/F/index.html", 5],
      ]
    end

    let!(:expected_integrated_layouts) do
      [
        ["master-top", "integration/master/top.layout.html", 3],
        ["partial-one", "integration/master/one.layout.html", 3],
      ]
    end

    let!(:expected_integrated_parts) do
      [
        ["master-recent", "integration/master/recent.part.html", 3],
        ["partial-header", "integration/master/header.part.html", 3],
      ]
    end

    it "#integrate" do
      master_node.in_partial_id = partial_node.id
      master_node.cur_user = user
      master_node.cur_node = master_node.parent
      master_node.cur_site = site

      # do integrate
      expect(master_node.integrate).to be_truthy, "validation error\n#{master_node.errors.full_messages.join("\n")}"

      # compare contents
      integrated_nodes = Cms::Node.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_pages = Cms::Page.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_layouts = Cms::Layout.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_parts = Cms::Part.site(site).map { |item| [item.name, item.filename, item.depth] }

      expect(integrated_nodes).to match_array expected_integrated_nodes
      expect(integrated_pages).to match_array expected_integrated_pages
      expect(integrated_layouts).to match_array expected_integrated_layouts
      expect(integrated_parts).to match_array expected_integrated_parts

      # check embeds ids
      article_node = Article::Node::Page.site(site).where(filename: "integration/master/D/F").first
      article_page = Article::Page.site(site).where(filename: "integration/master/page2.html").first

      expect(article_node.category_ids.include?(master_node.id)).to be_truthy
      expect(article_page.category_ids.include?(master_node.id)).to be_truthy
    end
  end

  context "partial is 1 depth master's descendants node" do
    before do
      Fs.rm_rf "#{site.path}/integration"
      Fs.rm_rf "#{site.path}/master"
      Fs.rm_rf "#{site.path}/partial"
    end
    # mater contents
    let!(:master_node) { create :category_node_node, site: site, user: user, filename: "master", name: "master" }

    let!(:master_child_node_A) { create :category_node_node, site: site, user: user, filename: "master/A", name: "master-A" }
    let!(:master_child_node_B) { create :category_node_page, site: site, user: user, filename: "master/B", name: "master-B" }
    let!(:master_child_node_C) { create :category_node_page, site: site, user: user, filename: "master/A/C", name: "master-A-C" }

    let!(:master_child_page_A) { create :cms_page, site: site, user: user, filename: "master/index.html", name: "master-index" }
    let!(:master_child_page_B) { create :article_page, site: site, user: user, filename: "master/page.html", name: "master-page" }
    let!(:master_child_page_C) { create :article_page, site: site, user: user, filename: "master/A/page.html", name: "master-page" }

    let!(:master_child_part_A) { create :cms_part, site: site, user: user, filename: "master/recent.part.html", name: "master-recent" }
    let!(:master_child_layout_A) { create :cms_layout, site: site, user: user, filename: "master/top.layout.html", name: "master-top" }

    # partial contents
    let!(:partial_node) { create :category_node_node, site: site, user: user, filename: "master/partial", name: "partial" }
    let!(:partial_child_node_D) { create :category_node_node, site: site, user: user, filename: "master/partial/D", name: "partial-D" }
    let!(:partial_child_node_E) { create :category_node_page, site: site, user: user, filename: "master/partial/E", name: "partial-E" }
    let!(:partial_child_node_F) { create :article_node_page, site: site, user: user, filename: "master/partial/D/F", name: "partial-D-F", category_ids: [partial_node.id] }

    let!(:partial_child_page_D) { create :article_page, site: site, user: user, filename: "master/partial/page2.html", name: "partial-page2", category_ids: [partial_node.id] }
    let!(:partial_child_page_E) { create :cms_page, site: site, user: user, filename: "master/partial/E/index.html", name: "partial-E-index" }
    let!(:partial_child_page_F) { create :cms_page, site: site, user: user, filename: "master/partial/D/F/index.html", name: "partial-D-F-index" }

    let!(:partial_child_part_B) { create :cms_part, site: site, user: user, filename: "master/partial/header.part.html", name: "partial-header" }
    let!(:partial_child_layout_B) { create :cms_layout, site: site, user: user, filename: "master/partial/one.layout.html", name: "partial-one" }

    let!(:expected_integrated_nodes) do
      [
        ["master", "master", 1],
        ["master-A", "master/A", 2],
        ["master-B", "master/B", 2],
        ["master-A-C", "master/A/C", 3],
        ["partial-D", "master/D", 2],
        ["partial-E", "master/E", 2],
        ["partial-D-F", "master/D/F", 3],
      ]
    end

    let!(:expected_integrated_pages) do
      [
        ["master-index", "master/index.html", 2],
        ["master-page", "master/page.html", 2],
        ["master-page", "master/A/page.html", 3],
        ["partial-page2", "master/page2.html", 2],
        ["partial-E-index", "master/E/index.html", 3],
        ["partial-D-F-index", "master/D/F/index.html", 4],
      ]
    end

    let!(:expected_integrated_layouts) do
      [
        ["master-top", "master/top.layout.html", 2],
        ["partial-one", "master/one.layout.html", 2],
      ]
    end

    let!(:expected_integrated_parts) do
      [
        ["master-recent", "master/recent.part.html", 2],
        ["partial-header", "master/header.part.html", 2],
      ]
    end

    it "#integrate" do
      master_node.in_partial_id = partial_node.id
      master_node.cur_user = user
      master_node.cur_node = master_node
      master_node.cur_site = site

      # do integrate
      expect(master_node.integrate).to be_truthy, "validation error\n#{master_node.errors.full_messages.join("\n")}"

      # compare contents
      integrated_nodes = Cms::Node.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_pages = Cms::Page.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_layouts = Cms::Layout.site(site).map { |item| [item.name, item.filename, item.depth] }
      integrated_parts = Cms::Part.site(site).map { |item| [item.name, item.filename, item.depth] }

      expect(integrated_nodes).to match_array expected_integrated_nodes
      expect(integrated_pages).to match_array expected_integrated_pages
      expect(integrated_layouts).to match_array expected_integrated_layouts
      expect(integrated_parts).to match_array expected_integrated_parts

      # check embeds ids
      article_node = Article::Node::Page.site(site).where(filename: "master/D/F").first
      article_page = Article::Page.site(site).where(filename: "master/page2.html").first

      expect(article_node.category_ids.include?(master_node.id)).to be_truthy
      expect(article_page.category_ids.include?(master_node.id)).to be_truthy
    end
  end
end
