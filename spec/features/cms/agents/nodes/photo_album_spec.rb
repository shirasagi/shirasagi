require 'spec_helper'

describe 'cms_agents_nodes_photo_album', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:layout) { create_cms_layout }
  let!(:photo_album_node) { create :cms_node_photo_album, cur_site: site, cur_node: node, layout_id: layout.id }

  context 'page with image files' do
    let!(:file) { create :cms_file, site_id: site.id, filename: "file.jpg" }
    let!(:file2) { create :cms_file, site_id: site.id, filename: "file2.png" }
    let!(:article_page) do
      create(:article_page, cur_site: site, cur_node: node, file_ids: [file.id, file2.id])
    end

    before { visit photo_album_node.url }
    it "is displayed" do
      within '#main > div.member-photos' do
        expect(page).to have_css("div.photo", count: 2)
        expect(page).to have_link(article_page.name, href: article_page.url)
        expect(page).to have_css(".title", text: article_page.name)
      end
    end
  end

  context 'page with pdf file' do
    let!(:file) { create :cms_file, site_id: site.id, filename: "file.pdf" }
    let!(:article_page) do
      create(:article_page, cur_site: site, cur_node: node, file_ids: [file.id])
    end

    before { visit photo_album_node.url }
    it "is not displayed" do
      expect(page).to have_css('#main > div.member-photos')
      expect(page).to have_no_css('#main > div.member-photos > div.photo')
      expect(page).to have_no_text(article_page.name)
    end
  end

  context 'with page "ads/banner"' do
    let!(:banner_page) { create(:ads_banner, cur_site: site, cur_node: node) }

    before { visit photo_album_node.url }

    it "is not displayed" do
      within '#main > div.member-photos > div.photo' do
        expect(page).to have_link(banner_page.name, href: banner_page.url)
        expect(page).to have_css(".title", text: banner_page.name)
      end
    end
  end
end
