require 'spec_helper'
describe Cms::CheckLinksJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:site_url) { "http://#{site.domain}" }
  let!(:layout) { create_cms_layout }

  let!(:index) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "index.html", html: html1 }
  let!(:docs) { create :article_node_page, cur_site: site, layout_id: layout.id, filename: "docs" }
  let!(:page1) { create :article_page, cur_site: site, layout_id: layout.id, filename: "docs/page1.html", html: html2 }
  let!(:page2) { create :article_page, cur_site: site, layout_id: layout.id, filename: "docs/page2.html" }
  let!(:page3) { create :article_page, cur_site: site, layout_id: layout.id, filename: "docs/page3.html" }

  let!(:html1) do
    h = []
    h << '<a href="/docs/">docs</a>'
    h << '<a href="/docs/page1.html">page1</a>'
    h << '<a href="/docs/page2.html">page2</a>'
    h << '<a href="/notfound1.html">notfound1</a>'
    h << '<!-- <a href="/commentout1.html">commentout1</a> -->'
    h << '<!--'
    h << '  <a href="/commentout2.html">commentout2.html</a>'
    h << '-->'
    h.join("\n")
  end

  let!(:html2) do
    h = []
    h << '<a href="/index.html">index</a>'
    h << '<a href="/docs/page3.html">page3</a>'
    h << '<a href="/notfound2.html">notfound2</a>'
    h.join("\n")
  end

  before do
    #Capybara.app_host = site_url
    described_class.bind(site_id: site).perform_now
  end

  context ".perform_now" do
    it do
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("#{site_url}/"))
        expect(log.logs).to include(include("  - #{site_url}/notfound1.html"))
        expect(log.logs).not_to include(include("  - #{site_url}/commentout1.html"))

        expect(log.logs).to include(include("#{site_url}/docs/page1.html"))
        expect(log.logs).to include(include("  - #{site_url}/notfound2.html"))
        expect(log.logs).not_to include(include("  - #{site_url}/commentout2.html"))
      end
    end
  end
end
