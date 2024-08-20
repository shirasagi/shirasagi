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

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/cms/node/import/member.csv" }
  let!(:csv_file) { Fs::UploadedFile.create_from_file(csv_path) }
  let!(:ss_file) { create(:ss_file, site: site, user: user, in_file: csv_file) }

  def find_node(filename)
    Cms::Node.site(site).where(filename: filename).first
  end

  def check_node(row, node)
    expect(row["﻿ファイル名"]).to eq node.basename
    expect(row["フォルダー属性"]).to eq node.route
    expect(row["タイトル"]).to eq node.name
    expect(row["一覧用タイトル"]).to eq node.index_name
    expect(row["並び順"]).to eq node.order.to_s
    expect(row["ショートカット"]).to eq node.label(:shortcut)
    expect(row["既定のモジュール"]).to eq node.label(:view_route)

    # meta addon
    expect(row["キーワード"]).to eq node.keywords.join("\n").presence
    expect(row["概要"]).to eq node.description
    expect(row["サマリー"]).to eq node.summary_html

    # no list addon
    # no category addon
    # release addon
    expect(row["公開日時種別"]).to eq node.label(:released_type)
    expect(row["ステータス"]).to eq node.label(:state)

    # cms groups addon
    expect(row["管理グループ"]).to eq node.groups.map(&:name).join("\n").presence
  end

  before do
    site.group_ids += [group1.id]
    site.update!
  end

  context "member nodes" do
    it "#import" do
      # Check initial node count
      expect(Cms::Node.count).to eq 0

      importer = described_class.new(site, node, user)
      importer.import(ss_file)

      # Check the node count after import
      csv = CSV.read(csv_path, headers: true)
      expect(Cms::Node.count).to eq 9 # 9 out of 12 are valid only

      node1 = find_node("blog")
      expect(node1).to be_present
      check_node(csv[0].to_h, node1)

      node2 = find_node("east")
      expect(node2).to be_present
      check_node(csv[1].to_h, node2)

      # invalid node
      node3 = find_node("shirasagi")
      expect(node3).to be_blank

      node4 = find_node("institution")
      expect(node4).to be_present
      check_node(csv[3].to_h, node4)

      node5 = find_node("search")
      expect(node5).to be_present
      check_node(csv[4].to_h, node5)

      node6 = find_node("spot")
      expect(node6).to be_present
      check_node(csv[5].to_h, node6)

      node7 = find_node("login")
      expect(node7).to be_present
      check_node(csv[6].to_h, node7)

      node8 = find_node("mypage")
      expect(node8).to be_present
      check_node(csv[7].to_h, node8)

      node9 = find_node("my_blog")
      expect(node9).to be_present
      check_node(csv[8].to_h, node9)

      node10 = find_node("my_photo")
      expect(node10).to be_present
      check_node(csv[9].to_h, node10)

      # invalid node
      node11 = find_node("my_group")
      expect(node11).to be_blank

      # invalid node
      node12 = find_node("registration")
      expect(node12).to be_blank
    end
  end
end
