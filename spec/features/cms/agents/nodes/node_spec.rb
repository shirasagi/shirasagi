require 'spec_helper'

describe "cms_agents_nodes_node", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :cms_node_node, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :cms_node, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector("article")
    end

    it "#kana", mecab: true do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector("article")
      expect(page).to have_selector("a[href='/node/item/']")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector(".tag-article")
      expect(page).to have_selector("a[href='/mobile/node/item/']")
    end
  end
end
