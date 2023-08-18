require 'spec_helper'

describe "cms_agents_parts_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:part) do
    create :cms_part_page, upper_html: '<div class="parts">', lower_html: '</div>', no_items_display_state: 'hide',
           substitute_html: '<div class="substitute">substitute</div>'
  end

  context "public" do
    let!(:item) { create :cms_page, filename: "item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_css(".parts")
      expect(page).to have_no_css(".substitute")
      expect(page).to have_selector("article")
    end

    it "#kana", mecab: true do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_css(".parts")
      expect(page).to have_no_css(".substitute")
      expect(page).to have_selector("article")
      expect(page).to have_selector("a[href='/item.html']")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_css(".parts")
      expect(page).to have_no_css(".substitute")
      expect(page).to have_selector(".tag-article")
      expect(page).to have_selector("a[href='/mobile/item.html']")
    end
  end

  context "closed" do
    let!(:item) { create :cms_page, filename: "item", state: 'closed' }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_no_css(".parts")
      expect(page).to have_css(".substitute")
      expect(page).to have_no_selector("article")
    end

    it "#kana", mecab: true do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_no_css(".parts")
      expect(page).to have_css(".substitute")
      expect(page).to have_no_selector("article")
      expect(page).to have_no_selector("a[href='/item.html']")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_no_css(".parts")
      expect(page).to have_css(".substitute")
      expect(page).to have_no_selector(".tag-article")
      expect(page).to have_no_selector("a[href='/mobile/item.html']")
    end
  end

  context "request_dir" do
    let!(:item) { create :cms_page, cur_node: node }
    let(:node2) { create :cms_node, layout_id: layout.id }
    let!(:item2) { create :cms_page, cur_node: node2 }

    before do
      part.conditions = [ "\#{request_dir}" ]
      part.save!
    end

    it do
      visit "#{node.full_url}/index.html"
      expect(page).to have_css(".parts", text: item.name)
      expect(page).to have_no_css(".parts", text: item2.name)

      visit "#{node2.full_url}/index.html"
      expect(page).to have_no_css(".parts", text: item.name)
      expect(page).to have_css(".parts", text: item2.name)
    end
  end
end
