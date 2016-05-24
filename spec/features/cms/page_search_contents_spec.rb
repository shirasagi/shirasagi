require 'spec_helper'

describe "cms_page_search_contents", dbscope: :example do
  let(:site) { cms_site }
  let(:name) { unique_id }
  let(:page_search) { create :cms_page_search, name: name, search_name: "A" }
  let(:index_path) { cms_page_search_contents_path site.id, page_search.id }

  context "without auth" do
    it "without login" do
      visit index_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end
  end

  context "show" do
    before { login_cms_user }

    context "show with no pages" do
      it do
        visit index_path
        expect(page).to have_css(".search-count", text: "0 件の検索結果")
      end
    end

    context "show with 1 cms page" do
      before do
        # node = create(:category_node_page, filename: 'base')
        create(:cms_page, cur_site: site, name: "[TEST]A", filename: "A.html", state: "public")
        # create(:article_page, cur_site: site, cur_node: node, name: "[TEST]B", filename: "B.html", state: "public")
      end

      it do
        visit index_path
        expect(page).to have_css(".search-count", text: "1 件の検索結果")
      end
    end

    context "show with 1 article page" do
      before do
        node = create(:category_node_page, filename: 'base')
        create(:article_page, cur_site: site, cur_node: node, name: "[TEST]A", filename: "A.html", state: "public")
      end

      it do
        visit index_path
        expect(page).to have_css(".search-count", text: "1 件の検索結果")
      end
    end
  end
end
