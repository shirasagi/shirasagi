require 'spec_helper'

describe Cms::NodeExporter, dbscope: :example do
  # sites
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  # nodes
  let!(:node1) do
    create(:article_node_page, order: 10,
      shortcut: "show",
      view_route: "article/page",
      layout: layout,
      page_layout: page_layout,

      # meta addon
      keywords: %w(keyword1 keyword2 keyword3),
      description: "description",
      summary_html: "<div>summary</div>",

      # list addon
      conditions: %w(cond1 cond2 cond3),
      sort: "released -1",
      limit: 30,
      new_days: 4,
      upper_html: "<div>upper</div>",
      lower_html: "<div>lower</div>",
      loop_format: "liquid",
      loop_html: '<div>#{loop}</div>',
      loop_liquid: '<div>{{liquid}}</div>',
      no_items_display_state: "show",
      substitute_html: "<div>substitute_html</div>",

      # category addon
      st_category_ids: [cate1.id, cate2.id],

      # groups addon
      group_ids: [group1.id, group2.id])

  end
  let!(:node2) { create :cms_node_page, order: 20 }
  let!(:node3) { create :cms_node_page, cur_node: node1, order: 20 }

  # relations
  let!(:layout) { create :cms_layout }
  let!(:page_layout) { create :cms_layout }

  let!(:cate1) { create :category_node_page, order: 30 }
  let!(:cate2) { create :category_node_page, order: 40 }

  let!(:group1) { create :cms_group, name: unique_id }
  let!(:group2) { create :cms_group, name: unique_id }

  context "export from root" do
    let!(:csv_params) { { encoding: "UTF-8" } }
    let!(:parent) { nil }

    it "#export" do
      criteria = Cms::Node.site(site).where(depth: 1) # bind site and depth conditions
      criteria = criteria.allow(:read, user, site: site, node: parent) # filter allowed nodes by permissions; but since the user is like an admin, all nodes are retrieved.
      criteria = criteria.order_by(order: 1)

      exporter = described_class.new(site: site, criteria: criteria)
      enumerable = exporter.enum_csv(csv_params)

      # enum csv encoded by UTF-8 with BOM
      # be careful that CSV.parse required non BOM UTF8 string
      csv = enumerable.to_a.join.delete_prefix(SS::Csv::UTF8_BOM)
      csv = CSV.parse(csv, headers: true)

      # there are 4 nodes on the root (node1, node2, cate1, cate2)
      expect(csv.size).to eq 4

      # check headers
      expect(csv.headers[0]).to eq "ファイル名"
      expect(csv.headers[1]).to eq "フォルダー属性"
      expect(csv.headers[2]).to eq "タイトル"
      expect(csv.headers[3]).to eq "一覧用タイトル"
      expect(csv.headers[4]).to eq "並び順"
      expect(csv.headers[5]).to eq "レイアウト"
      expect(csv.headers[6]).to eq "ページレイアウト"
      expect(csv.headers[7]).to eq "ショートカット"
      expect(csv.headers[8]).to eq "既定のモジュール"
      expect(csv.headers[9]).to eq "キーワード"
      expect(csv.headers[10]).to eq "概要"
      expect(csv.headers[11]).to eq "サマリー"
      expect(csv.headers[12]).to eq "検索条件(URL)"
      expect(csv.headers[13]).to eq "リスト並び順"
      expect(csv.headers[14]).to eq "表示件数"
      expect(csv.headers[15]).to eq "NEWマーク期間"
      expect(csv.headers[16]).to eq "ループHTML形式"
      expect(csv.headers[17]).to eq "上部HTML"
      expect(csv.headers[18]).to eq "ループHTML(SHIRASAGI形式)"
      expect(csv.headers[19]).to eq "下部HTML"
      expect(csv.headers[20]).to eq "ループHTML(Liquid形式)"
      expect(csv.headers[21]).to eq "ページ未検出時表示"
      expect(csv.headers[22]).to eq "代替HTML"
      expect(csv.headers[23]).to eq "カテゴリー設定"
      expect(csv.headers[24]).to eq "公開日時種別"
      expect(csv.headers[25]).to eq "公開日時"
      expect(csv.headers[26]).to eq "ステータス"
      expect(csv.headers[27]).to eq "管理グループ"

      # first row is node1
      row = csv[0]

      #TODO and Memo:
      # check attributes with following rules
      #
      # 1. inputting directly fields
      #    e.g. ファイル名, タイトル...
      #    localized string or integer fields
      #    simply outputs a string or integer directly in this case
      #
      #    others area array like fields
      #    e.g. キーワード, 検索条件(URL)...
      #    outputs a string separated by line breaks ("\n") in this case
      #
      # 2. options fields (like a select tags or checkboxes in web view)
      #    e.g. ショートカット, 既定のモジュール...
      #    these fields are non localized string keys
      #    node1.shortcut's database value is "show" or "hide"
      #    but these are displayed as "表示", "非表示" in web view
      #    so csv import feature should suppport localized value (表示", "非表示")
      #
      #    localized value can referenced by label method in node object
      #    like a node1.label(:shortcut)
      #
      # 3. relations
      #    relation fields are outputs relation item's name (or filename label)
      #
      # as a normal use case, the CSV output here must be imported
      # please note that the CSV output here must be imported (download csv format must be same as import csv format)

      # basic
      expect(row["ファイル名"]).to eq node1.basename
      expect(row["フォルダー属性"]).to eq node1.route
      expect(row["タイトル"]).to eq node1.name
      expect(row["一覧用タイトル"]).to eq node1.index_name
      expect(row["並び順"]).to eq node1.order.to_s
      expect(row["レイアウト"]).to eq "#{layout.name} (#{layout.filename})"
      expect(row["ページレイアウト"]).to eq "#{page_layout.name} (#{page_layout.filename})"
      expect(row["ショートカット"]).to eq node1.label(:shortcut)
      expect(row["既定のモジュール"]).to eq node1.label(:view_route)

      # meta addon
      expect(row["キーワード"]).to eq node1.keywords.join("\n")
      expect(row["概要"]).to eq node1.description
      expect(row["サマリー"]).to eq node1.summary_html

      # list addon
      expect(row["検索条件(URL)"]).to eq node1.conditions.join("\n")
      expect(row["リスト並び順"]).to eq node1.label(:sort)
      expect(row["表示件数"]).to eq node1.limit.to_s
      expect(row["NEWマーク期間"]).to eq node1.new_days.to_s
      expect(row["ループHTML形式"]).to eq node1.label(:loop_format)
      expect(row["上部HTML"]).to eq node1.upper_html
      expect(row["ループHTML(SHIRASAGI形式)"]).to eq node1.loop_html
      expect(row["下部HTML"]).to eq node1.lower_html
      expect(row["ループHTML(Liquid形式)"]).to eq node1.loop_liquid
      expect(row["ページ未検出時表示"]).to eq node1.label(:no_items_display_state)
      expect(row["代替HTML"]).to eq node1.substitute_html

      # category addon
      expect(row["カテゴリー設定"]).to eq node1.st_categories.map { |cate| "#{cate.name} (#{cate.filename})" }.join("\n")

      # release addon
      expect(row["公開日時種別"]).to eq node1.label(:released_type)
      expect(row["公開日時"]).to eq I18n.l(node1.released, format: :picker)
      expect(row["ステータス"]).to eq node1.label(:state)

      # cms groups addon
      expect(row["管理グループ"]).to eq node1.groups.map(&:name).join("\n")
    end
  end

  context "export from parent node" do
    let!(:csv_params) { { encoding: "UTF-8" } }
    let!(:parent) { node1 }

    it "#export" do
      #TODO and Memo:
      # create test case of export from node1.

      # there is 1 node on the parent node (node3)
      #expect(csv.size).to eq 1
    end
  end
end
