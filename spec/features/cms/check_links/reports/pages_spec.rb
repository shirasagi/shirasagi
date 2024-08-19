require 'spec_helper'

describe "cms/check_links/pages", type: :feature, dbscope: :example, js: true, raise_server_errors: false do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:index) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "index.html", html: html1 }
  let!(:docs) { create(:article_node_page, site: site, layout_id: layout.id, filename: "docs") }
  let!(:docs_page1) { create(:article_page, site: site, layout_id: layout.id, filename: "docs/page1.html", html: html2) }

  let!(:html1) do
    h = []
    h << '<a href="/">index</a>'
    h << '<a href="/docs/">docs</a>'
    h << '<a href="/docs/?キー=値">docs</a>'
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
  let(:page_count) { "#{I18n.t("ss.page")}2#{I18n.t("ss.units.count")}" }
  let(:link_count) { 2 }
  let(:index_report_created) { index.latest_check_links_report.created }
  let(:page1_report_created) { docs_page1.latest_check_links_report.created }

  def execute_job
    Cms::CheckLinksJob.bind(site_id: site.id).perform_now
  end

  def latest_report
    Cms::CheckLinks::Report.site(site).first
  end

  def report_label(time)
    I18n.t("cms.notices.check_links_report_created", time: time.strftime("%Y/%m/%d %H:%M"))
  end

  def visit_latest_report_pages
    visit index_path
    within ".list-items" do
      expect(page).to have_selector('.list-item', count: 1)
      first(".list-item a.title").click
    end
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      execute_job

      visit_latest_report_pages
      within "#main" do
        expect(page).to have_css(".list-items", text: page_count)
        within "tbody" do
          expect(page).to have_css("td a", text: index.name)
          expect(page).to have_css("td a", text: docs_page1.name)
        end
      end

      # page addon
      visit_latest_report_pages
      within "#main tbody" do
        click_on index.name
      end

      within ".check-links" do
        header = I18n.t(
          "cms.notices.check_links_report_header",
          count: link_count, time: I18n.l(index_report_created, format: :picker)
        )
        expect(page).to have_css("h2", text: header)
      end

      visit_latest_report_pages
      within "#main tbody" do
        click_on docs_page1.name
      end

      within ".check-links" do
        header = I18n.t(
          "cms.notices.check_links_report_header",
          count: link_count, time: I18n.l(page1_report_created, format: :picker)
        )
        expect(page).to have_css("h2", text: header)
      end
      click_on I18n.t("ss.links.back_to_index")

      # preview
      visit_latest_report_pages
      within "#main tbody" do
        within all("tr")[0] do
          click_on I18n.t("cms.links.check_preview")
        end
      end
      switch_to_window(windows.last)
      wait_for_document_loading

      within "div#main" do
        expect(page).to have_no_css("a.ss-check-links-error", text: "[リンク切れ]index.html")
        expect(page).to have_css("a.ss-check-links-error", text: "[リンク切れ]notfound1.html")
        expect(page).to have_css("a.ss-check-links-error", text: "[リンク切れ]notfound2.html")
      end
    end
  end
end
