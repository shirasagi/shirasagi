require 'spec_helper'

describe "cms_check_links_pages", dbscope: :example do
  let!(:site) { cms_site }
  let!(:site2) { create :cms_site, name: "another", host: "another", domains: "another.localhost.jp" }
  let!(:index_path) { cms_check_links_nodes_path site.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    context "error not exists" do
      let!(:node1) { create(:article_node_page, site: site, filename: "docs") }
      let!(:node2) { create(:faq_node_page, site: site, filename: "faq") }
      let!(:item1) { create(:article_page, filename: "docs/page1.html") }
      let!(:item2) { create(:article_page, filename: "docs/page2.html") }
      let!(:item3) { create(:faq_page, filename: "faq/page3.html") }
      let!(:item4) { create(:faq_page, filename: "faq/page4.html") }

      let!(:site2_node1) { create(:article_node_page, site: site2, filename: "docs") }
      let!(:site2_node2) { create(:faq_node_page, site: site2, filename: "faq") }
      let!(:site2_item1) { create(:article_page, site: site2, filename: "docs/page1.html") }
      let!(:site2_item2) { create(:article_page, site: site2, filename: "docs/page2.html") }
      let!(:site2_item3) { create(:faq_page, site: site2, filename: "faq/page3.html") }
      let!(:site2_item4) { create(:faq_page, site: site2, filename: "faq/page4.html") }

      it do
        visit index_path
        expect(current_path).not_to eq sns_login_path
      end
    end

    context "error exists" do
      let!(:time_now) { Time.zone.now }
      let!(:error_urls) { ["/docs/error.html"] }
      let!(:node1) do
        create(:article_node_page, site: site, filename: "docs",
          check_links_errors_updated: time_now, check_links_errors: error_urls)
      end
      let!(:node2) do
        create(:faq_node_page, site: site, filename: "faq")
      end
      let!(:item1) do
        create(:article_page, filename: "docs/page1.html",
          check_links_errors_updated: time_now, check_links_errors: error_urls)
      end
      let!(:item2) do
        create(:article_page, filename: "docs/page2.html",
          check_links_errors_updated: time_now, check_links_errors: error_urls)
      end
      let!(:item3) do
        create(:faq_page, filename: "faq/page3.html")
      end
      let!(:item4) do
        create(:faq_page, filename: "faq/page4.html")
      end

      let!(:site2_node1) do
        create(:article_node_page, site: site2, filename: "docs",
          check_links_errors_updated: time_now, check_links_errors: error_urls)
      end
      let!(:site2_node2) do
        create(:faq_node_page, site: site2, filename: "faq")
      end
      let!(:site2_item1) do
        create(:article_page, site: site2, filename: "docs/page1.html",
          check_links_errors_updated: time_now, check_links_errors: error_urls)
      end
      let!(:site2_item2) do
        create(:article_page, site: site2, filename: "docs/page2.html",
          check_links_errors_updated: time_now, check_links_errors: error_urls)
      end
      let!(:site2_item3) do
        create(:faq_page, site: site2, filename: "faq/page3.html")
      end
      let!(:site2_item4) do
        create(:faq_page, site: site2, filename: "faq/page4.html")
      end

      it do
        visit index_path
        expect(current_path).not_to eq sns_login_path

        expect(page).to have_link node1.name
        expect(page).not_to have_link node2.name

        expect(page).not_to have_link item1.name
        expect(page).not_to have_link item2.name
        expect(page).not_to have_link item3.name
        expect(page).not_to have_link item4.name

        expect(page).not_to have_link site2_node1.name
        expect(page).not_to have_link site2_node2.name

        expect(page).not_to have_link site2_item1.name
        expect(page).not_to have_link site2_item2.name
        expect(page).not_to have_link site2_item3.name
        expect(page).not_to have_link site2_item4.name

        click_link node1.name
        expect(page).to have_link node1.name
      end
    end
  end
end
