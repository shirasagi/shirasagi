require 'spec_helper'

describe "category_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :category_node_page, layout_id: layout.id, filename: "node", limit: 2, sort: "name" }
  let(:docs)   { create :article_node_page, layout_id: layout.id, filename: "docs" }
  let!(:item1) { create :cms_page, filename: "node/item1", name: "a_#{unique_id}" }
  let!(:item2) { create :cms_page, filename: "node/item2", name: "b_#{unique_id}" }
  let!(:item3) { create :article_page, filename: "docs/item1", name: "c_#{unique_id}", category_ids: [node.id] }
  let!(:item4) { create :article_page, filename: "docs/item2", name: "d_#{unique_id}", category_ids: [node.id] }
  let!(:item5) { create :article_page, filename: "docs/item3", name: "e_#{unique_id}", category_ids: [node.id] }

  before do
    Capybara.app_host = "http://#{site.domain}"

    # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
    FileUtils.rm_rf site.path
    FileUtils.mkdir_p site.path
  end

  shared_examples "what pagination in public is" do
    context "when url is just node's url" do
      it do
        visit node.url
        expect(page).to have_css(".pages")
        expect(page).to have_selector(".pages article")

        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          expect(page).to have_link("2", href: "#{node.url}index.p2.html")
          expect(page).to have_link("3", href: "#{node.url}index.p3.html")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_link("1", href: node.url)
          expect(page).to have_css(".page.current", text: "2")
          expect(page).to have_link("3", href: "#{node.url}index.p3.html")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item5.name
        within ".pagination" do
          expect(page).to have_link("1", href: node.url)
          expect(page).to have_link("2", href: "#{node.url}index.p2.html")
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end
    end

    context "when url ends with '/'" do
      it do
        visit "#{node.url}/"
        expect(page).to have_css(".pages")
        expect(page).to have_selector(".pages article")

        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          expect(page).to have_link("2", href: "#{node.url}index.p2.html")
          expect(page).to have_link("3", href: "#{node.url}index.p3.html")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_link("1", href: node.url)
          expect(page).to have_css(".page.current", text: "2")
          expect(page).to have_link("3", href: "#{node.url}index.p3.html")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item5.name
        within ".pagination" do
          expect(page).to have_link("1", href: node.url)
          expect(page).to have_link("2", href: "#{node.url}index.p2.html")
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end
    end

    context "when url ends with '/index.html'" do
      it do
        visit "#{node.url}/index.html"
        expect(page).to have_css(".pages")
        expect(page).to have_selector(".pages article")

        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_css(".page.current", text: "1")
          expect(page).to have_link("2", href: "#{node.url}index.p2.html")
          expect(page).to have_link("3", href: "#{node.url}index.p3.html")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_no_link item5.name
        within ".pagination" do
          expect(page).to have_link("1", href: node.url)
          expect(page).to have_css(".page.current", text: "2")
          expect(page).to have_link("3", href: "#{node.url}index.p3.html")
          click_on I18n.t("views.pagination.next")
        end

        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_link item5.name
        within ".pagination" do
          expect(page).to have_link("1", href: node.url)
          expect(page).to have_link("2", href: "#{node.url}index.p2.html")
          expect(page).to have_css(".page.current", text: "3")
          expect(page).to have_no_link I18n.t("views.pagination.next")
        end
      end
    end
  end

  context "with dynamic" do
    before do
      ::FileUtils.rm_rf(node.path)
    end

    after do
      ::FileUtils.rm_rf(node.path)
    end

    it_behaves_like "what pagination in public is"
  end

  context "with static" do
    before do
      expect do
        ::Cms::Node::GenerateJob.bind(site_id: site, node_id: node).perform_now
      end.to output(include("#{node.url}index.p3.html\n")).to_stdout
    end

    it_behaves_like "what pagination in public is"
  end
end
