require 'spec_helper'

describe "category_agents_parts_node", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:part) do
    create :category_part_node, loop_format: loop_format, upper_html: upper_html, lower_html: lower_html
  end
  let!(:layout) { create_cms_layout part }
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
  let!(:page2) { create(:cms_page, cur_node: cate_d13, layout: layout) }

  before { Cms::Page.all.each { |page| ::FileUtils.rm_f(page.path) } }

  # category/node パーツは、唯一相対ディレクトリのパーツだが予測できない動作をする。
  # 正確にいうと第二階層までは兄弟を、第三階層以降では親の兄弟を表示する。
  # その仕様を以下に記述する
  context "'category/node' part is relative part" do
    context "when loop_format is 'shirasagi'" do
      let(:loop_format) { 'shirasagi' }
      let(:upper_html) { '<div id="category-part-e0">' }
      let(:lower_html) { '</div> <!-- #category-part-e0 -->' }

      it do
        visit cate_d1.full_url
        within "#category-part-e0" do
          # 第一階層にあるカテゴリーの場合、第一階層にあるカテゴリー（自身の兄弟）を一覧に表示する。
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
        within "#category-part-e0" do
          # 第二階層にあるカテゴリーの場合、第二階層にあるカテゴリー（自身の兄弟）を一覧に表示する。
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
        within "#category-part-e0" do
          # 第三階層にあるカテゴリーの場合、第二階層にあるカテゴリー（親の兄弟）を一覧に表示する。
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
        within "#category-part-e0" do
          # 第四階層にあるカテゴリーの場合、第三階層にあるカテゴリー（親の兄弟）を一覧に表示する。
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
        within "#category-part-e0" do
          # 第一階層にあるページの場合、第一階層にあるカテゴリー（自身の兄弟）を一覧に表示する。
          expect(page).to have_css("article", count: 2)
          expect(page).to have_css(".item-#{cate_d1.basename}", text: cate_d1.name)
          expect(page).to have_css(".item-#{cate_d2.basename}", text: cate_d2.name)
        end

        expect(page1.depth).to eq 2
        visit page1.full_url
        within "#category-part-e0" do
          # 第二階層にあるページの場合、第二階層にあるカテゴリー（自身の兄弟）を一覧に表示する。
          expect(page).to have_css("article", count: 3)
          expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
          expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
          expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
        end

        expect(page2.depth).to eq 3
        visit page2.full_url
        within "#category-part-e0" do
          # 第三階層にあるページの場合、第二階層にあるカテゴリー（親の兄弟）を一覧に表示する。
          expect(page).to have_css("article", count: 3)
          expect(page).to have_css(".item-#{cate_d11.basename}", text: cate_d11.name)
          expect(page).to have_css(".item-#{cate_d12.basename}", text: cate_d12.name)
          expect(page).to have_css(".item-#{cate_d13.basename}", text: cate_d13.name)
        end
      end
    end
  end
end
