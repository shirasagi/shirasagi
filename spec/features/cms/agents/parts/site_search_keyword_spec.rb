require 'spec_helper'

describe "cms_agents_parts_site_search_keyword", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:keyword1) { "keyword-#{unique_id}" }
  let!(:keyword2) { "keyword-#{unique_id}" }
  let!(:keywords) { [ keyword1, keyword2 ] }
  let!(:upper_html) { '<div class="spec-site_search_keyword">' }
  let!(:part) do
    create :cms_part_site_search_keyword, site_search_keywords: keywords, upper_html: upper_html, lower_html: "</div>"
  end
  let!(:layout) { create_cms_layout part }
  let!(:index_page) { create :cms_page, layout: layout }

  before do
    ::FileUtils.rm_f(index_page.path)
  end

  context "with public site search node" do
    let!(:site_search) { create :cms_node_site_search, layout: layout, state: "public" }

    it do
      visit index_page.full_url
      within ".spec-site_search_keyword" do
        expect(page).to have_css("[rel=\"nofollow\"]", text: keyword1)
        expect(page).to have_css("[rel=\"nofollow\"]", text: keyword2)
      end

      click_on keyword1
      within ".site-search-keyword" do
        expect(page).to have_css("[value=\"#{keyword1}\"]")
      end
    end
  end

  context "with closed site search node" do
    let!(:site_search) { create :cms_node_site_search, layout: layout, state: "closed" }

    it do
      visit index_page.full_url
      expect(page).to have_no_css(".spec-site_search_keyword")
    end
  end

  context "without site search node" do
    it do
      visit index_page.full_url
      expect(page).to have_no_css(".spec-site_search_keyword")
    end
  end
end
