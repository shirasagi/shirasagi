require 'spec_helper'

describe "cms/check_links/export", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:index) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "index.html", html: html1 }
  let!(:docs) { create(:article_node_page, site: site, layout_id: layout.id, filename: "docs") }
  let!(:docs_page1) { create(:article_page, site: site, layout_id: layout.id, filename: "docs/page1.html", html: html2) }

  let!(:html1) do
    h = []
    h << '<a href="/">index</a>'
    h << '<a href="/docs/">docs</a>'
    h << '<a href="/docs/index.html">docs</a>'
    h << '<a href="/docs/page1.html">page.html</a>'
    h << '<a href="/docs/notfound1.html">notfound1.html</a>'
    h << '<a href="/docs/notfound2.html">notfound2.html</a>'
    h.join("\n")
  end

  let!(:html2) do
    h = []
    h << '<a href="/">index</a>'
    h << '<a href="/docs/notfound1.html">notfound1.html</a>'
    h << '<a href="/docs/notfound2.html">notfound2.html</a>'
    h.join("\n")
  end

  let(:index_path) { cms_check_links_reports_path site.id }

  def generate_nodes
    Cms::Node::GenerateJob.bind(site_id: site.id).perform_now
  end

  def execute_job
    Cms::CheckLinksJob.bind(site_id: site.id).perform_now
  end

  def latest_report
    Cms::CheckLinks::Report.site(site).first
  end

  context "export csv" do
    before { login_cms_user }

    it "pages" do
      execute_job

      visit index_path
      within ".list-items" do
        expect(page).to have_selector('.list-item', count: 1)
        first(".list-item a.title").click
      end

      click_on I18n.t("ss.buttons.download")
      expect(page.response_headers["Transfer-Encoding"]).to eq "chunked"
      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv = csv.encode("UTF-8", "SJIS")
      csv = ::CSV.parse(csv)
      expect(csv.size).to eq 3
    end
  end
end
