require 'spec_helper'

describe 'cms_agents_nodes_photo_album', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:layout) { create_cms_layout }
  let!(:photo_album_node) { create :cms_node_photo_album, cur_site: site, cur_node: node, layout_id: layout.id }

  context 'page with allowed files' do
    let!(:file) { create :cms_file, site_id: site.id , filename: "file.jpg"}
    let!(:file2) { create :cms_file, site_id: site.id , filename: "file2.png"}
    let!(:article_page) do
      create :article_page,
      cur_site: site,
      cur_node: node,
      file_ids: [file.id, file2.id]
    end

    before { visit photo_album_node.url }
    it "is displayed" do
      expect(status_code).to eq 200
      expect(page).to have_css('body > div.member-photos > div#photo-album')
      expect(page).to have_text(article_page.name)
    end
  end

  context 'page with disapprove file' do
    let!(:file) { create :cms_file, site_id: site.id , filename: "file.pdf"}
    let!(:article_page) do
      create :article_page,
      cur_site: site,
      cur_node: node,
      file_ids: [file.id]
    end

    before { visit photo_album_node.url }
    it "is not displayed" do
      expect(status_code).to eq 200
      expect(page).to have_css('body > div.member-photos')
      expect(page).not_to have_css('body > div.member-photos > div#photo-album')
      expect(page).not_to have_text(article_page.name)
    end
  end

end
