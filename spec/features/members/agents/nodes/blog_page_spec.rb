require 'spec_helper'

describe "member_agents_nodes_blog_page", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:genre) { unique_id.to_s }
  let(:layout) { create :member_blog_layout }
  let!(:blog) { create :member_node_blog, filename: "blog" }
  let!(:blog_page) do
    create :member_node_blog_page, layout_id: layout.id, page_layout_id: layout.id, filename: "blog/blog_page", genres: [genre]
  end

  context "public" do
    let!(:item) { create :member_blog_page, filename: "blog/blog_page/item", genres: [genre] }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit blog_page.url
      expect(page).to have_selector("img.thumb")
      expect(page).to have_selector("a", text: blog_page.genres.first)
      expect(page).to have_selector("div.member-blog-pages")

      first('.blog a').click
      expect(current_path).to eq item.url
    end
  end
end
