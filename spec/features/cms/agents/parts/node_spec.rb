require 'spec_helper'

describe "cms_agents_parts_node", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:part)   { create :cms_part_node }

  context "public" do
    let!(:item) { create :cms_node, filename: "item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector("article")
    end

    it "#kana" do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector("article")
      expect(page).to have_selector("a[href='/item/']")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector(".tag-article")
      expect(page).to have_selector("a[href='/mobile/item/']")
    end
  end
end
