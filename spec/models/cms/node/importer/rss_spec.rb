require 'spec_helper'

describe Cms::NodeImporter, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { nil }

  let!(:group1) { create :ss_group, name: "シラサギ市", order: 10 }
  let!(:group2) { create :ss_group, name: "シラサギ市/企画政策部", order: 20 }
  let!(:group3) { create :ss_group, name: "シラサギ市/企画政策部/政策課", order: 30 }
  let!(:group4) { create :ss_group, name: "シラサギ市/企画政策部/広報課", order: 40 }
  let!(:group5) { create :ss_group, name: "シラサギ市/危機管理部", order: 50 }
  let!(:group6) { create :ss_group, name: "シラサギ市/危機管理部/管理課", order: 60 }
  let!(:group7) { create :ss_group, name: "シラサギ市/危機管理部/防災課", order: 70 }

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/cms/node/import/rss.csv" }
  let!(:csv_file) { Fs::UploadedFile.create_from_file(csv_path) }
  let!(:ss_file) { create(:ss_file, site: site, user: user, in_file: csv_file) }

  before do
    site.group_ids += [group1.id]
    site.update!
  end

  context "rss nodes" do
    it "#import" do
      # Check initial node count
      expect(Cms::Node.count).to eq 0

      importer = described_class.new(site, node, user)
      importer.import(ss_file)

      # Check the node count after import
      csv = CSV.read(csv_path, headers: true)
      expect(Rss::Node::Base.count).to eq(csv.size)

      Rss::Node::Base.each_with_index do |node, index|
        row = csv[index].to_hash

        expect(row["﻿ファイル名"]).to eq node.basename
        expect(row["フォルダー属性"]).to eq node.route
        expect(row["タイトル"]).to eq node.name
        expect(row["一覧用タイトル"]).to eq node.index_name
        expect(row["並び順"]).to eq node.order.to_s
        expect(row["ショートカット"]).to eq node.label(:shortcut)
        expect(row["既定のモジュール"]).to eq node.label(:view_route)

        # meta addo
        expect(row["キーワード"]).to eq node.keywords.join("\n").presence
        expect(row["概要"]).to eq node.description
        expect(row["サマリー"]).to eq node.summary_html

        # no list addon
        # category addon
        expect(row["カテゴリー設定"]).to eq node.st_categories.map { |cate| "#{cate.name} (#{cate.filename})" }.join("\n").presence

        # release addon
        expect(row["公開日時種別"]).to eq node.label(:released_type)
        expect(row["ステータス"]).to eq node.label(:state)

        # cms groups addon
        expect(row["管理グループ"]).to eq node.groups.map(&:name).join("\n").presence
      end
    end
  end
end
