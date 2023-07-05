require 'spec_helper'

describe "move_cms_pages", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:index_path) { cms_pages_path site.id }

  around do |example|
    save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', true)
    perform_enqueued_jobs do
      example.run
    end
    SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
  end

  context "with auth", js: true do
    let(:page_html) { '<a href="/A/B/C/">/A/B/C/</a>' }
    let(:page2_html) { '<a href="/page.html">page.html</a>' }
    let(:layout_layout_html) { "<a href='#{site.full_url}page.html'>page.html</a><a href='#{site.full_url}A/B/C/'>/A/B/C/</a>" }
    let(:part_part_html) { '<a href="/page.html ">page.html</a><a href="/A/B/C/ ">/A/B/C/</a>' }

    before { login_cms_user }
    before(:each) do
      create(:cms_page, filename: "page.html", name: "page", html: page_html)
      create(:cms_page, filename: "A/B/C/page2.html", name: "page2", html: page2_html)
      create(:cms_layout, filename: "layout.layout.html", name: "layout", html: layout_layout_html)
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
      expect(Fs.exist?("#{site.path}/page.html")).to be_truthy

      visit move_page_path
      within "form" do
        fill_in "destination", with: "A/page"
        click_button I18n.t('ss.buttons.move')
      end

      #expect(current_path).to eq move_page_path
      expect(page).to have_css("form#item-form .current-filename", text: "A/page.html")

      expect(Fs.exist?("#{site.path}/page.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/A/page.html")).to be_truthy

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      item = Cms::Page.where(filename: "A/B/C/page2.html").first
      visit cms_page_path(site.id, item)
      expect(page).to have_selector('span', text: I18n.t('history.options.action.replace_urls'), count: 1)

      item = Cms::Node.where(filename: "A/B/C").first
      move_node_path = move_node_conf_path(site.id, item)
      expect(Fs.exist?("#{site.path}/A/B/C/page2.html")).to be_truthy

      visit move_node_path
      within "form" do
        fill_in "destination", with: "D/E"
        click_button I18n.t('ss.buttons.move')
      end

      expect(current_path).to eq move_node_path
      expect(page).to have_css("form#item-form .current-filename", text: "D/E")

      expect(Fs.exist?("#{site.path}/A/B/C/page2.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/D/E/page2.html")).to be_truthy

      expect(Job::Log.count).to eq 2
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      item = Cms::Page.where(filename: "A/page.html").first
      visit cms_page_path(site.id, item)
      expect(page).to have_selector('span', text: I18n.t('history.options.action.replace_urls'), count: 1)

      visit move_page_path
      within "form" do
        fill_in "destination", with: "D/E/page"
        click_button I18n.t('ss.buttons.move')
      end
      #expect(current_path).to eq move_page_path
      expect(page).to have_css("form#item-form .current-filename", text: "D/E/page.html")

      expect(Fs.exist?("#{site.path}/A/page.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/D/E/page.html")).to be_truthy

      expect(Job::Log.count).to eq 3
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      item = Cms::Page.where(filename: "D/E/page2.html").first
      visit cms_page_path(site.id, item)
      expect(page).to have_selector('span', text: I18n.t('history.options.action.replace_urls'), count: 2)

      visit move_node_path
      within "form" do
        fill_in "destination", with: "A/B/C"
        click_button I18n.t('ss.buttons.move')
      end
      expect(current_path).to eq move_node_path
      expect(page).to have_css("form#item-form .current-filename", text: "A/B/C")

      expect(Fs.exist?("#{site.path}/D/E/page.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/D/E/page2.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/A/B/C/page.html")).to be_truthy
      expect(Fs.exist?("#{site.path}/A/B/C/page2.html")).to be_truthy

      expect(Job::Log.count).to eq 4
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      item = Cms::Page.where(filename: "A/B/C/page.html").first
      visit cms_page_path(site.id, item)
      expect(page).to have_selector('span', text: I18n.t('history.options.action.replace_urls'), count: 2)

      item = Cms::Page.where(filename: "A/B/C/page2.html").first
      visit cms_page_path(site.id, item)
      expect(page).to have_selector('span', text: I18n.t('history.options.action.replace_urls'), count: 3)
    end
  end
end
