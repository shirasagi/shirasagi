require 'spec_helper'

describe "cms_agents_parts_node2", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout part }

  describe "#list_origin" do
    let!(:node1) { create :cms_node_node, layout: layout }
    let!(:node2_1) { create :cms_node_node, layout: layout, cur_node: node1 }
    let!(:node2_2) { create :cms_node_node, layout: layout, cur_node: node1 }
    let!(:node2_3) { create :cms_node_node, layout: layout, cur_node: node1 }

    let!(:index_page) { create :cms_page, layout: layout, filename: "index.html", cur_node: node2_1 }
    let!(:other_page1) { create :cms_page, layout: layout, cur_node: node2_2 }
    let!(:other_page2) { create :cms_page, layout: layout, cur_node: node2_3 }
    let!(:depth1_page) { create :cms_page, layout: layout }

    before do
      ::FileUtils.rm_f(node1.path)
    end

    # 浮動型モードのみ
    context "with 'content'" do
      context "default case" do
        let!(:part) do
          create :cms_part_node2, upper_html: upper_html, lower_html: lower_html, list_origin: 'content'
        end
        let!(:upper_html) { '<div id="node-part-e0">' }
        let!(:lower_html) { '</div> <!-- #node-part-e0 -->' }

        it do
          # depth1
          visit node1.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 1)
            expect(page).to have_link node1.name
          end

          visit depth1_page.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 1)
            expect(page).to have_link node1.name
          end

          # depth2
          visit node2_1.url # index_page
          within "#node-part-e0" do
            expect(page).to have_no_selector("a")
            expect(page).to have_no_link node2_1.name
            expect(page).to have_no_link node2_2.name
            expect(page).to have_no_link node2_3.name
          end

          visit node2_2.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end

          visit node2_3.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end

          visit index_page.url
          within "#node-part-e0" do
            expect(page).to have_no_selector("a")
            expect(page).to have_no_link node2_1.name
            expect(page).to have_no_link node2_2.name
            expect(page).to have_no_link node2_3.name
          end

          visit other_page1.url
          within "#node-part-e0" do
            expect(page).to have_no_selector("a")
            expect(page).to have_no_link node2_1.name
            expect(page).to have_no_link node2_2.name
            expect(page).to have_no_link node2_3.name
          end

          visit other_page2.url
          within "#node-part-e0" do
            expect(page).to have_no_selector("a")
            expect(page).to have_no_link node2_1.name
            expect(page).to have_no_link node2_2.name
            expect(page).to have_no_link node2_3.name
          end
        end
      end

      # リストの起点を以下に設定する
      # フォルダー: アクセスされたフォルダーが配置されているフォルダー
      # ページ: アクセスされたページが配置されているフォルダーの親フォルダー
      context "show same list on page and node" do
        let!(:part) do
          create :cms_part_node2, upper_html: upper_html, lower_html: lower_html, list_origin: 'content',
            origin_of_page: "parent2", origin_of_node: "parent1"
        end
        let!(:upper_html) { '<div id="node-part-e0">' }
        let!(:lower_html) { '</div> <!-- #node-part-e0 -->' }

        it do
          # depth1
          visit node1.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 1)
            expect(page).to have_link node1.name
          end

          visit depth1_page.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 1)
            expect(page).to have_link node1.name
          end

          # depth2
          visit node2_1.url # index_page
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end

          visit node2_2.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end

          visit node2_3.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end

          visit index_page.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end

          visit other_page1.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end

          visit other_page2.url
          within "#node-part-e0" do
            expect(page).to have_selector("a", count: 3)
            expect(page).to have_link node2_1.name
            expect(page).to have_link node2_2.name
            expect(page).to have_link node2_3.name
          end
        end
      end
    end
  end
end
