require 'spec_helper'

describe "article_agents_nodes_search", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :article_node_search, layout_id: layout.id, filename: "node" }

  let!(:category1) { create :category_node_page, cur_site: site, layout: layout, order: 30 }
  let!(:category2) { create :category_node_page, cur_site: site, layout: layout, order: 20 }
  let!(:category3) { create :category_node_page, cur_site: site, layout: layout, order: 10 }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"

      # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
      FileUtils.rm_rf site.path
      FileUtils.mkdir_p site.path
    end

    context "basic" do
      it "#index" do
        visit node.url
        within ".article-search.search" do
          expect(page).to have_no_css(".category")
          expect(page).to have_css(".keyword")
          expect(page).to have_css(".submitters")
        end
      end
    end

    context "set st_categories" do
      before do
        node.st_category_ids = [category1.id, category2.id, category3.id]
        node.update!
      end

      it "#index" do
        visit node.url
        within ".article-search.search" do
          within "[name=\"category\"]" do
            expect(page).to have_selector("option[value]", count: 4)
            within all("option[value]")[0] do
              expect(page.text).to be_blank
            end
            within all("option[value]")[1] do
              expect(page).to have_text(category3.name)
            end
            within all("option[value]")[2] do
              expect(page).to have_text(category2.name)
            end
            within all("option[value]")[3] do
              expect(page).to have_text(category1.name)
            end
          end
          expect(page).to have_css(".keyword")
          expect(page).to have_css(".submitters")
        end
      end
    end
  end
end
