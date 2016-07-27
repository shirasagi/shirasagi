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
    let!(:master_child_node_C) { create :article_node_page, site: site, user: user, filename: "master/A/C", name: "master-A-C", category_ids: [master_node.id] }

    let!(:master_child_page_A) { create :cms_page, site: site, user: user, filename: "master/index.html", name: "master-index" }
    let!(:master_child_page_B) { create :article_page, site: site, user: user, filename: "master/page.html", name: "master-page" }
    let!(:master_child_page_C) { create :article_page, site: site, user: user, filename: "master/A/page.html", name: "master-page", category_ids: [master_node.id] }

    let!(:master_child_part_A) { create :cms_part, site: site, user: user, filename: "master/recent.part.html", name: "master-recent" }
    let!(:master_child_layout_A) { create :cms_layout, site: site, user: user, filename: "master/top.layout.html", name: "master-top" }

    let!(:expected_integrated_nodes) do
      [
        ["master", "master", 1],
        ["master-A", "master/A", 2],
        ["master-B", "master/B", 2],
        ["master-A-C", "master/A/C", 3],
        ["partial", "partial", 1],
      ]
    end

    it "#split" do
      master_node.in_partial_name = "partial"
      master_node.in_partial_basename = "partial"
      master_node.cur_user = user
      master_node.cur_node = master_node
      master_node.cur_site = site

      # do split
      expect(master_node.split).to be_truthy, "validation error\n#{master_node.errors.full_messages.join("\n")}"
      partial_node = master_node.class.site(site).find_by(filename: "partial")

      # compare contents
      integrated_nodes = Cms::Node.site(site).map { |item| [item.name, item.filename, item.depth] }
      expect(integrated_nodes).to match_array expected_integrated_nodes

      # check embeds ids
      article_node = Article::Node::Page.site(site).where(filename: "master/A/C").first
      article_page_1 = Article::Page.site(site).where(filename: "master/page.html").first
      article_page_2 = Article::Page.site(site).where(filename: "master/A/page.html").first

      expect(article_node.category_ids.include?(partial_node.id)).to be_truthy
      expect(article_page_1.category_ids.include?(partial_node.id)).to be_falsy
      expect(article_page_2.category_ids.include?(partial_node.id)).to be_truthy
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
    let!(:master_child_node_C) { create :article_node_page, site: site, user: user, filename: "integration/master/A/C", name: "master-A-C", category_ids: [master_node.id] }

    let!(:master_child_page_A) { create :cms_page, site: site, user: user, filename: "integration/master/index.html", name: "master-index" }
    let!(:master_child_page_B) { create :article_page, site: site, user: user, filename: "integration/master/page.html", name: "master-page" }
    let!(:master_child_page_C) { create :article_page, site: site, user: user, filename: "integration/master/A/page.html", name: "master-page", category_ids: [master_node.id] }

    let!(:master_child_part_A) { create :cms_part, site: site, user: user, filename: "integration/master/recent.part.html", name: "master-recent" }
    let!(:master_child_layout_A) { create :cms_layout, site: site, user: user, filename: "integration/master/top.layout.html", name: "master-top" }

    let!(:expected_integrated_nodes) do
      [
        ["integration", "integration", 1],
        ["master", "integration/master", 2],
        ["master-A", "integration/master/A", 3],
        ["master-B", "integration/master/B", 3],
        ["master-A-C", "integration/master/A/C", 4],
        ["partial", "integration/partial", 2],
      ]
    end

    it "#split" do
      master_node.in_partial_name = "partial"
      master_node.in_partial_basename = "partial"
      master_node.cur_user = user
      master_node.cur_node = master_node
      master_node.cur_site = site

      # do split
      expect(master_node.split).to be_truthy, "validation error\n#{master_node.errors.full_messages.join("\n")}"
      partial_node = master_node.class.site(site).find_by(filename: "integration/partial")

      # compare contents
      integrated_nodes = Cms::Node.site(site).map { |item| [item.name, item.filename, item.depth] }
      expect(integrated_nodes).to match_array expected_integrated_nodes

      # check embeds ids
      article_node = Article::Node::Page.site(site).where(filename: "integration/master/A/C").first
      article_page_1 = Article::Page.site(site).where(filename: "integration/master/page.html").first
      article_page_2 = Article::Page.site(site).where(filename: "integration/master/A/page.html").first

      expect(article_node.category_ids.include?(partial_node.id)).to be_truthy
      expect(article_page_1.category_ids.include?(partial_node.id)).to be_falsy
      expect(article_page_2.category_ids.include?(partial_node.id)).to be_truthy
    end
  end
end
