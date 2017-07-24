require 'spec_helper'

describe "recommend_agents_parts_similarity", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:site2) { create :cms_site, name: "another", host: "another", domains: "another.localhost.jp" }

  let!(:layout) { create_cms_layout part }
  let!(:part) { create :recommend_part_similarity, filename: "node/part" }
  let!(:node) { create :cms_node, layout_id: layout.id, filename: "node" }

  let!(:item1) { create :article_page, layout_id: layout.id, filename: "node/page1.html" }
  let!(:item2) { create :article_page, layout_id: layout.id, filename: "node/page2.html" }
  let!(:item3) { create :article_page, layout_id: layout.id, filename: "node/page3.html" }
  let!(:item4) { create :article_page, layout_id: layout.id, filename: "node/page4.html" }
  let!(:item5) { create :article_page, layout_id: layout.id, filename: "node/page5.html" }

  let!(:score1_1) { create :recommend_similarity_score, site: site, key: item1.url, path: item2.url, score: 0.5 }
  let!(:score1_2) { create :recommend_similarity_score, site: site, key: item1.url, path: item3.url, score: 0.45 }
  let!(:score1_3) { create :recommend_similarity_score, site: site, key: item1.url, path: item4.url, score: 0.4 }
  let!(:score1_4) { create :recommend_similarity_score, site: site, key: item1.url, path: item5.url, score: 0.35 }

  let!(:score2_1) { create :recommend_similarity_score, site: site, key: item2.url, path: item1.url, score: 0.33 }
  let!(:score2_2) { create :recommend_similarity_score, site: site, key: item2.url, path: item3.url, score: 0.3 }
  let!(:score2_3) { create :recommend_similarity_score, site: site, key: item2.url, path: item4.url, score: 0.27 }
  let!(:score2_4) { create :recommend_similarity_score, site: site, key: item2.url, path: item5.url, score: 0.24 }

  let!(:site2_score1_1) { create :recommend_similarity_score, site: site2, key: item1.url, path: item2.url, score: 0.35 }
  let!(:site2_score1_2) { create :recommend_similarity_score, site: site2, key: item1.url, path: item3.url, score: 0.4 }
  let!(:site2_score1_3) { create :recommend_similarity_score, site: site2, key: item1.url, path: item4.url, score: 0.45 }
  let!(:site2_score1_4) { create :recommend_similarity_score, site: site2, key: item1.url, path: item5.url, score: 0.5 }

  let!(:site2_score2_1) { create :recommend_similarity_score, site: site2, key: item2.url, path: item1.url, score: 0.24 }
  let!(:site2_score2_2) { create :recommend_similarity_score, site: site2, key: item2.url, path: item3.url, score: 0.27 }
  let!(:site2_score2_3) { create :recommend_similarity_score, site: site2, key: item2.url, path: item4.url, score: 0.3 }
  let!(:site2_sscore2_4) { create :recommend_similarity_score, site: site2, key: item2.url, path: item5.url, score: 0.33 }

  context "public", js: true do
    before do
      Capybara.app_host = "http://#{site.domain}"

      # regenerate static htmls
      Cms::Page.each(&:save)
    end

    it "#index" do
      visit item1.url

      expect(page).to have_css(".recommend-similarity")
      expect(page).to have_link item2.name
      expect(page).to have_link item3.name
      expect(page).to have_link item4.name
      expect(page).to have_link item5.name

      i1 = page.html.index(item2.url)
      i2 = page.html.index(item3.url)
      i3 = page.html.index(item4.url)
      i4 = page.html.index(item5.url)

      expect((i1 < i2) && (i2 < i3) && (i3 < i4)).to be_truthy

      visit item2.url
      expect(page).to have_css(".recommend-similarity")
      expect(page).to have_link item1.name
      expect(page).to have_link item3.name
      expect(page).to have_link item4.name
      expect(page).to have_link item5.name

      i1 = page.html.index(item1.url)
      i2 = page.html.index(item3.url)
      i3 = page.html.index(item4.url)
      i4 = page.html.index(item5.url)

      expect((i1 < i2) && (i2 < i3) && (i3 < i4)).to be_truthy
    end
  end
end
