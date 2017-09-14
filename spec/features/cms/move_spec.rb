require 'spec_helper'

describe "move_cms_pages" do
  subject(:site) { cms_site }
  subject(:index_path) { cms_pages_path site.id }

  context "with auth", js: true do
    let(:page_html) { '<a href="/A/B/C/">/A/B/C/</a>' }
    let(:page2_html) { '<a href="/page.html">page.html</a>' }
    let(:layout_layout_html) { '<a href="/page.html">page.html</a><a href="/A/B/C/">/A/B/C/</a>' }
    let(:part_part_html) { '<a href="/page.html">page.html</a><a href="/A/B/C/">/A/B/C/</a>' }

    before { login_cms_user }
    before(:each) do
      create(:cms_page, filename: "page.html", name: "page", html: page_html)
      create(:cms_page, filename: "A/B/C/page2.html", name: "page2", html: page2_html)
      create(:cms_layout, filename: "layout.layout.html", name: "latyout", html: layout_layout_html)
      create(:cms_part_free, filename: "part.part.html", name: "part", html: part_part_html)
      create(:cms_node_page, site: site, filename: "A", name: "A")
      create(:cms_node_page, site: site, filename: "A/B", name: "B" )
      create(:cms_node_page, site: site, filename: "A/B/C", name: "C" )
      create(:cms_node_page, site: site, filename: "D", name: "D" )
    end
    after(:each) do
      Fs.rm_rf "#{site.path}/A"
      Fs.rm_rf "#{site.path}/D"
    end

    it "#move" do
      item = Cms::Page.where(filename: "page.html").first
      move_page_path = move_cms_page_path(site.id, item)
      expect(Fs.exists?("#{site.path}/page.html")).to eq(true)

      visit move_page_path
      within "form" do
        fill_in "destination", with: "A/page"
        click_button "保存"
      end

      #expect(current_path).to eq move_page_path
      expect(page).to have_css("form#item-form h2", text: "A/page.html")

      expect(Fs.exists?("#{site.path}/page.html")).to eq(false)
      expect(Fs.exists?("#{site.path}/A/page.html")).to eq(true)

      item = Cms::Node.where(filename: "A/B/C").first
      move_node_path = move_node_conf_path(site.id, item)
      expect(Fs.exists?("#{site.path}/A/B/C/page2.html")).to eq(true)

      visit move_node_path
      within "form" do
        fill_in "destination", with: "D/E"
        click_button "保存"
      end

      expect(current_path).to eq move_node_path
      expect(page).to have_css("form#item-form h2", text: "D/E")

      expect(Fs.exists?("#{site.path}/A/B/C/page2.html")).to eq(false)
      expect(Fs.exists?("#{site.path}/D/E/page2.html")).to eq(true)

      visit move_page_path
      within "form" do
        fill_in "destination", with: "D/E/page"
        click_button "保存"
      end
      #expect(current_path).to eq move_page_path
      expect(page).to have_css("form#item-form h2", text: "D/E/page.html")

      expect(Fs.exists?("#{site.path}/A/page.html")).to eq(false)
      expect(Fs.exists?("#{site.path}/D/E/page.html")).to eq(true)

      visit move_node_path
      within "form" do
        fill_in "destination", with: "A/B/C"
        click_button "保存"
      end
      expect(current_path).to eq move_node_path
      expect(page).to have_css("form#item-form h2", text: "A/B/C")

      expect(Fs.exists?("#{site.path}/D/E/page.html")).to eq(false)
      expect(Fs.exists?("#{site.path}/D/E/page2.html")).to eq(false)
      expect(Fs.exists?("#{site.path}/A/B/C/page.html")).to eq(true)
      expect(Fs.exists?("#{site.path}/A/B/C/page2.html")).to eq(true)
    end
  end
end
