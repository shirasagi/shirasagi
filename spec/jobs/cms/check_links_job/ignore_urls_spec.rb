require 'spec_helper'
describe Cms::CheckLinksJob, dbscope: :example do
  let!(:site) { cms_site }

  let!(:layout) { create_cms_layout }
  let!(:index) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "index.html", html: index_html }
  let!(:page1) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "page1.html", html: page1_html }
  let!(:page2) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "page2.html", html: page2_html }
  let!(:page3) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "page3.html", html: page3_html }
  let!(:page4) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "page4.html", html: page4_html }

  let!(:url1) { "http://sample.example.jp" }
  let!(:url2) { "/inquiry/?group=1&page=1" }
  let!(:url3) { "/inquiry/?group=2&page=2" }
  let!(:url4) { "/docs/sample/" }

  let!(:index_html) do
    [
      "<a href=\"#{page1.url}\">#{page1.url}</a>",
      "<a href=\"#{page2.url}\">#{page2.url}</a>",
      "<a href=\"#{page3.url}\">#{page3.url}</a>",
      "<a href=\"#{page4.url}\">#{page4.url}</a>"
    ].join
  end
  let!(:page1_html) { "<a href=\"#{url1}\">#{url1}</a>" }
  let!(:page2_html) { "<a href=\"#{url2}\">#{url2}</a>" }
  let!(:page3_html) { "<a href=\"#{url3}\">#{url3}</a>" }
  let!(:page4_html) { "<a href=\"#{url4}\">#{url4}</a>" }

  before do
    @net_connect_allowed = WebMock.net_connect_allowed?
    WebMock.disable_net_connect!(allow_localhost: true)
    WebMock.reset!

    stub_request(:get, index.full_url).to_return(body: Fs.read(index.path),
      status: 200, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, page1.full_url).to_return(body: Fs.read(page1.path),
      status: 200, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, page2.full_url).to_return(body: Fs.read(page2.path),
      status: 200, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, page3.full_url).to_return(body: Fs.read(page3.path),
      status: 200, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, page4.full_url).to_return(body: Fs.read(page4.path),
      status: 200, headers: { 'Content-Type' => 'text/html' })

    stub_request(:get, url1).to_return(body: "", status: 404, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, ::File.join(site.full_url, url2)).to_return(body: "",
      status: 404, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, ::File.join(site.full_url, url3)).to_return(body: "",
      status: 404, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, ::File.join(site.full_url, url4)).to_return(body: "",
      status: 404, headers: { 'Content-Type' => 'text/html' })
  end

  after do
    WebMock.reset!
    WebMock.allow_net_connect! if @net_connect_allowed
  end

  context "no ignore_urls" do
    it do
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("[4 errors]"))
        expect(log.logs).to include(include("  - #{url1}"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url2)}"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url3)}"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url4)}"))
      end
    end
  end

  context "ignore_urls all" do
    let!(:item1) { create :check_links_ignore_url, name: url1, kind: "all" }
    let!(:item2) { create :check_links_ignore_url, name: "/inquiry/", kind: "all" }

    it do
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("[3 errors]"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url2)}"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url3)}"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url4)}"))
      end
    end
  end

  context "ignore_urls start_with" do
    let!(:item1) { create :check_links_ignore_url, name: "/inquiry/", kind: "start_with" }
    let!(:item2) { create :check_links_ignore_url, name: "/sample/", kind: "start_with" }

    it do
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("[2 errors]"))
        expect(log.logs).to include(include("  - #{url1}"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url4)}"))
      end
    end
  end

  context "ignore_urls end_with" do
    let!(:item1) { create :check_links_ignore_url, name: "?group=1&page=1", kind: "end_with" }
    let!(:item2) { create :check_links_ignore_url, name: "/sample/", kind: "end_with" }

    it do
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("[2 errors]"))
        expect(log.logs).to include(include("  - #{url1}"))
        expect(log.logs).to include(include("  - #{::File.join(site.full_url, url3)}"))
      end
    end
  end

  context "ignore_urls include" do
    let!(:item1) { create :check_links_ignore_url, name: "inquiry", kind: "include" }
    let!(:item2) { create :check_links_ignore_url, name: "sample", kind: "include" }

    it do
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("[0 errors]"))
      end
    end
  end
end
