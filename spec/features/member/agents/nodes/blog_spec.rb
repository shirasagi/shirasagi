require 'spec_helper'

describe "member_agents_nodes_blog", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :member_node_blog, layout_id: layout.id, filename: "node" }
  let(:blog_layout) { create :member_blog_layout }

  context "public" do
    let!(:item) { create :member_node_blog_page, layout_id: blog_layout.id, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(page).to have_selector("div.member-blogs")
      expect(page).to have_selector("article.blog.thumb")
      expect(page).to have_selector("img.thumb")

      first('.member-blogs a').click
      expect(current_path).to eq item.url
    end
  end
end
