require 'spec_helper'

describe "cms_agents_parts_node2", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }

  # パーツ "category/node" は、唯一浮動型のリストパーツで、特に予測できない動作をする。
  # そして、パーツ "cms/node" は固定型のリストパーツだが、予測できない動作をする。
  # そこで、動作が予測可能なパーツ "cms/node2" を開発した。
  # その仕様を以下に記述する。
  #
  # ※固定型のリストパーツ: アクセスしているノードやページによらず、パーツが配置された階層をもとにリストを表示する。
  # ※浮動型のリストパーツ: アクセスしているノードやページによって、表示するリストが異なる。
  describe "#list_origin" do
    let!(:cate_d1) do
      create(
        :category_node_node, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-node-1">', lower_html: '</div>'
      )
    end
    let!(:cate_d11) do
      create(
        :category_node_node, cur_node: cate_d1, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-node-1-1">', lower_html: '</div>'
      )
    end
    let!(:cate_d12) do
      create(
        :category_node_node, cur_node: cate_d1, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-node-1-2">', lower_html: '</div>'
      )
    end
    let!(:cate_d13) do
      create(
        :category_node_page, cur_node: cate_d1, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1-3">', lower_html: '</div>'
      )
    end
    let!(:cate_d111) do
      create(
        :category_node_page, cur_node: cate_d11, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1-1-1">', lower_html: '</div>'
      )
    end
    let!(:cate_d112) do
      create(
        :category_node_node, cur_node: cate_d11, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-node-1-1-2">', lower_html: '</div>'
      )
    end
    let!(:cate_d121) do
      create(
        :category_node_page, cur_node: cate_d12, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1-2-1">', lower_html: '</div>'
      )
    end
    let!(:cate_d122) do
      create(
        :category_node_page, cur_node: cate_d12, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1-2-2">', lower_html: '</div>'
      )
    end

    let!(:cate_d1121) do
      create(
        :category_node_page, cur_node: cate_d112, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1-1-2-1">', lower_html: '</div>'
      )
    end
    let!(:cate_d1122) do
      create(
        :category_node_page, cur_node: cate_d112, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1-1-2-2">', lower_html: '</div>'
      )
    end

    let!(:cate_d2) do
      create(
        :category_node_node, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-node-2">', lower_html: '</div>'
      )
    end
    let!(:cate_d21) do
      create(
        :category_node_page, cur_node: cate_d2, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-2-1">', lower_html: '</div>'
      )
    end
    let!(:page0) { create(:cms_page, layout: layout, category_ids: Category::Node::Page.all.pluck(:id)) }
    let!(:page1) { create(:cms_page, cur_node: cate_d1, layout: layout) }
    let!(:page2) { create(:cms_page, cur_node: cate_d12, layout: layout) }

    before do
      part_html = '{{ part "/' + part.filename.sub(/\..*/, '') + '" }}' + "\n"
      layout.html = layout.html.sub("{{ yield }}", part_html + "{{ yield }}")
      layout.save!

      Cms::Page.all.each { |page| ::FileUtils.rm_f(page.path) }
    end

    # 固定型モードの仕様（配備された階層依存）
    context "with default" do
      context "located at root (depth 1)" do
        let!(:part) do
          create :cms_part_node2, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html
        end

        before do
          expect(part.depth).to eq 1
        end

        context "when loop_format is 'shirasagi'" do
          let(:loop_format) { 'shirasagi' }
          let(:upper_html) { '<div id="node-part-e0">' }
          let(:lower_html) { '</div> <!-- #node-part-e0 -->' }

          it do
            visit cate_d1.full_url
            within "#node-part-e0" do
              # 第一階層にあるフォルダーの場合、第一階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end
            within "#category-node-node-1" do
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            visit cate_d12.full_url
            within "#node-part-e0" do
              # 第二階層にあフォルダーであっても（パーツが第一階層に配置されているので）第一階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end
            within "#category-node-node-1-2" do
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d122.basename}", text: cate_d122.name)
            end

            visit cate_d111.full_url
            within "#node-part-e0" do
              # 第三階層にあフォルダーであっても（パーツが第一階層に配置されているので）第一階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end
            within "#category-node-page-1-1-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            visit cate_d1121.full_url
            within "#node-part-e0" do
              # 第四階層にあフォルダーであっても（パーツが第一階層に配置されているので）第一階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end
            within "#category-node-page-1-1-2-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            expect(page0.depth).to eq 1
            visit page0.full_url
            within "#node-part-e0" do
              # 第一階層にあるページの場合、第一階層にあるカテゴリー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end

            expect(page1.depth).to eq 2
            visit page1.full_url
            within "#node-part-e0" do
              # 第二階層にあるページであっても、（パーツが第一階層に配置されているので）第二階層にあるカテゴリー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end

            expect(page2.depth).to eq 3
            visit page2.full_url
            within "#node-part-e0" do
              # 第三階層にあるページであっても、（パーツが第一階層に配置されているので）第二階層にあるカテゴリー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end
          end
        end
      end

      context "located at depth 2" do
        let!(:part) do
          create :cms_part_node2, cur_node: cate_d1, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html
        end

        before do
          expect(part.depth).to eq 2
        end

        context "when loop_format is 'shirasagi'" do
          let(:loop_format) { 'shirasagi' }
          let(:upper_html) { '<div id="node-part-e0">' }
          let(:lower_html) { '</div> <!-- #node-part-e0 -->' }

          it do
            visit cate_d1.full_url
            within "#node-part-e0" do
              # （パーツが第二階層に配置されているので）第二階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end
            within "#category-node-node-1" do
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            visit cate_d12.full_url
            within "#node-part-e0" do
              # （パーツが第二階層に配置されているので）第二階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end
            within "#category-node-node-1-2" do
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d122.basename}", text: cate_d122.name)
            end

            visit cate_d111.full_url
            within "#node-part-e0" do
              # （パーツが第二階層に配置されているので）第二階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end
            within "#category-node-page-1-1-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            visit cate_d1121.full_url
            within "#node-part-e0" do
              # （パーツが第二階層に配置されているので）第二階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end
            within "#category-node-page-1-1-2-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            expect(page0.depth).to eq 1
            visit page0.full_url
            within "#node-part-e0" do
              # （パーツが第二階層に配置されているので）第二階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            expect(page1.depth).to eq 2
            visit page1.full_url
            within "#node-part-e0" do
              # （パーツが第二階層に配置されているので）第二階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            expect(page2.depth).to eq 3
            visit page2.full_url
            within "#node-part-e0" do
              # （パーツが第二階層に配置されているので）第二階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end
          end
        end
      end

      context "located at depth 3" do
        let!(:part) do
          create :cms_part_node2, cur_node: cate_d11, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html
        end

        before do
          expect(part.depth).to eq 3
        end

        context "when loop_format is 'shirasagi'" do
          let(:loop_format) { 'shirasagi' }
          let(:upper_html) { '<div id="node-part-e0">' }
          let(:lower_html) { '</div> <!-- #node-part-e0 -->' }

          it do
            visit cate_d1.full_url
            within "#node-part-e0" do
              # （パーツが第三階層に配置されているので）第三階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end
            within "#category-node-node-1" do
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            visit cate_d12.full_url
            within "#node-part-e0" do
              # （パーツが第三階層に配置されているので）第三階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end
            within "#category-node-node-1-2" do
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d122.basename}", text: cate_d122.name)
            end

            visit cate_d111.full_url
            within "#node-part-e0" do
              # （パーツが第三階層に配置されているので）第三階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end
            within "#category-node-page-1-1-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            visit cate_d1121.full_url
            within "#node-part-e0" do
              # （パーツが第三階層に配置されているので）第三階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end
            within "#category-node-page-1-1-2-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            expect(page0.depth).to eq 1
            visit page0.full_url
            within "#node-part-e0" do
              # （パーツが第三階層に配置されているので）第三階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end

            expect(page1.depth).to eq 2
            visit page1.full_url
            within "#node-part-e0" do
              # （パーツが第三階層に配置されているので）第三階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end

            expect(page2.depth).to eq 3
            visit page2.full_url
            within "#node-part-e0" do
              # （パーツが第三階層に配置されているので）第三階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end
          end
        end
      end

      context "located at depth 4" do
        let!(:part) do
          create :cms_part_node2, cur_node: cate_d112, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html
        end

        before do
          expect(part.depth).to eq 4
        end

        context "when loop_format is 'shirasagi'" do
          let(:loop_format) { 'shirasagi' }
          let(:upper_html) { '<div id="node-part-e0">' }
          let(:lower_html) { '</div> <!-- #node-part-e0 -->' }

          it do
            visit cate_d1.full_url
            within "#node-part-e0" do
              # （パーツが第四階層に配置されているので）第四階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end
            within "#category-node-node-1" do
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            visit cate_d12.full_url
            within "#node-part-e0" do
              # （パーツが第四階層に配置されているので）第四階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end
            within "#category-node-node-1-2" do
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d122.basename}", text: cate_d122.name)
            end

            visit cate_d111.full_url
            within "#node-part-e0" do
              # （パーツが第四階層に配置されているので）第四階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end
            within "#category-node-page-1-1-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            visit cate_d1121.full_url
            within "#node-part-e0" do
              # （パーツが第四階層に配置されているので）第四階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end
            within "#category-node-page-1-1-2-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            expect(page0.depth).to eq 1
            visit page0.full_url
            within "#node-part-e0" do
              # （パーツが第四階層に配置されているので）第四階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end

            expect(page1.depth).to eq 2
            visit page1.full_url
            within "#node-part-e0" do
              # （パーツが第四階層に配置されているので）第四階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end

            expect(page2.depth).to eq 3
            visit page2.full_url
            within "#node-part-e0" do
              # （パーツが第四階層に配置されているので）第四階層にあるフォルダー（パーツ自身の兄弟）を一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end
          end
        end
      end
    end

    # 浮動型モードの仕様（アクセスされたコンテンツ依存）
    context "with 'content'" do
      context "located at root (depth 1)" do
        let!(:part) do
          create :cms_part_node2, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html,
                 list_origin: 'content'
        end

        before do
          expect(part.depth).to eq 1
        end

        context "when loop_format is 'shirasagi'" do
          let(:loop_format) { 'shirasagi' }
          let(:upper_html) { '<div id="node-part-e0">' }
          let(:lower_html) { '</div> <!-- #node-part-e0 -->' }

          it do
            visit cate_d1.full_url
            within "#node-part-e0" do
              # 第一階層にあるカテゴリーにアクセスした場合、第一階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end
            within "#category-node-node-1" do
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            visit cate_d12.full_url
            within "#node-part-e0" do
              # 第二階層にあるカテゴリーにアクセスした場合、第二階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end
            within "#category-node-node-1-2" do
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d122.basename}", text: cate_d122.name)
            end

            visit cate_d111.full_url
            within "#node-part-e0" do
              # 第三階層にあるカテゴリーにアクセスした場合、第三階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end
            within "#category-node-page-1-1-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            visit cate_d1121.full_url
            within "#node-part-e0" do
              # 第四階層にあるカテゴリーにアクセスした場合、第四階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end
            within "#category-node-page-1-1-2-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            expect(page0.depth).to eq 1
            visit page0.full_url
            within "#node-part-e0" do
              # 第一階層にあるページにアクセスした場合、第一階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end

            expect(page1.depth).to eq 2
            visit page1.full_url
            within "#node-part-e0" do
              # 第二階層にあるページにアクセスした場合、第二階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            expect(page2.depth).to eq 3
            visit page2.full_url
            within "#node-part-e0" do
              # 第三階層にあるページにアクセスした場合、第三階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
            end
          end
        end
      end

      context "located at depth 5" do
        let!(:part) do
          create :cms_part_node2, cur_node: cate_d1122, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html,
                 list_origin: 'content'
        end

        before do
          expect(part.depth).to eq 5
        end

        context "when loop_format is 'shirasagi'" do
          let(:loop_format) { 'shirasagi' }
          let(:upper_html) { '<div id="node-part-e0">' }
          let(:lower_html) { '</div> <!-- #node-part-e0 -->' }

          it do
            visit cate_d1.full_url
            within "#node-part-e0" do
              # 第一階層にあるカテゴリーにアクセスした場合、第一階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end
            within "#category-node-node-1" do
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            visit cate_d12.full_url
            within "#node-part-e0" do
              # 第二階層にあるカテゴリーにアクセスした場合、第二階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end
            within "#category-node-node-1-2" do
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d122.basename}", text: cate_d122.name)
            end

            visit cate_d111.full_url
            within "#node-part-e0" do
              # 第三階層にあるカテゴリーにアクセスした場合、第三階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d111.basename}", text: cate_d111.name)
              expect(page).to have_css(".item-#{cate_d112.basename}", text: cate_d112.name)
            end
            within "#category-node-page-1-1-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            visit cate_d1121.full_url
            within "#node-part-e0" do
              # 第四階層にあるカテゴリーにアクセスした場合、第四階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1121.basename}", text: cate_d1121.name)
              expect(page).to have_css(".item-#{cate_d1122.basename}", text: cate_d1122.name)
            end
            within "#category-node-page-1-1-2-1" do
              expect(page).to have_css("article", count: 1)
              expect(page).to have_css(".item-#{File.basename(page0.filename, ".*")}", text: page0.name)
            end

            expect(page0.depth).to eq 1
            visit page0.full_url
            within "#node-part-e0" do
              # 第一階層にあるページにアクセスした場合、第一階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
              expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
            end

            expect(page1.depth).to eq 2
            visit page1.full_url
            within "#node-part-e0" do
              # 第二階層にあるページにアクセスした場合、第二階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 3)
              expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
              expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
              expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
            end

            expect(page2.depth).to eq 3
            visit page2.full_url
            within "#node-part-e0" do
              # 第三階層にあるページにアクセスした場合、第三階層にあるカテゴリーを一覧に表示する。
              expect(page).to have_css("article", count: 2)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
              expect(page).to have_css(".item-#{cate_d121.basename}", text: cate_d121.name)
            end
          end
        end
      end
    end
  end

  describe "#node_routes" do
    let!(:cate_node_node) do
      create(
        :category_node_node, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-node-1">', lower_html: '</div>'
      )
    end
    let!(:cate_node_page) do
      create(
        :category_node_page, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1">', lower_html: '</div>'
      )
    end
    let!(:article_node_page) do
      create(
        :article_node_page, layout: layout,
        loop_format: 'shirasagi', upper_html: '<div id="category-node-page-1">', lower_html: '</div>'
      )
    end
    let(:loop_format) { 'shirasagi' }
    let(:upper_html) { '<div id="node-part-e0">' }
    let(:lower_html) { '</div> <!-- #node-part-e0 -->' }

    before do
      part_html = '{{ part "/' + part.filename.sub(/\..*/, '') + '" }}' + "\n"
      layout.html = layout.html.sub("{{ yield }}", part_html + "{{ yield }}")
      layout.save!

      Cms::Page.all.each { |page| ::FileUtils.rm_f(page.path) }
    end

    context "without node_routes" do
      let!(:part) do
        create(:cms_part_node2, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html)
      end

      it do
        visit cate_node_node.full_url
        within "#node-part-e0" do
          expect(page).to have_css("article", count: 3)
          expect(page).to have_css(".item-#{cate_node_node.basename}", text: cate_node_node.name)
          expect(page).to have_css(".item-#{cate_node_page.basename}", text: cate_node_page.name)
          expect(page).to have_css(".item-#{article_node_page.basename}", text: article_node_page.name)
        end
      end
    end

    context "with node_routes" do
      let!(:part) do
        create(
          :cms_part_node2, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html,
          node_routes: [ cate_node_node.route, cate_node_page.route ]
        )
      end

      it do
        visit cate_node_node.full_url
        within "#node-part-e0" do
          expect(page).to have_css("article", count: 2)
          expect(page).to have_css(".item-#{cate_node_node.basename}", text: cate_node_node.name)
          expect(page).to have_css(".item-#{cate_node_page.basename}", text: cate_node_page.name)
        end
      end
    end
  end
end
