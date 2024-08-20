require 'spec_helper'

describe Cms::NodeImporter, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { nil }

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/cms/node/import/cms.csv" }
  let!(:csv_file) { Fs::UploadedFile.create_from_file(csv_path) }
  let!(:ss_file) { create(:ss_file, site: site, user: user, in_file: csv_file) }

  def find_node(filename)
    Cms::Node.site(site).where(filename: filename).first
  end

  context "cms nodes" do
    it "#import" do
      # Check initial node count
      expect(Cms::Node.count).to eq(0)

      importer = described_class.new(site, node, user)
      importer.import(ss_file)

      # Check the node count after import
      csv = CSV.read(csv_path, headers: true)
      expect(Cms::Node.count).to eq(csv.size)

      Cms::Node.each_with_index do |node1, index|
        row = csv[index].to_hash

        if node1.respond_to?(:basename) && node1.basename.present?
          expect(row["﻿ファイル名"]).to eq node1.basename
        end
        if node1.respond_to?(:route) && node1.route.present?
          expect(row["フォルダー属性"]).to eq node1.route
        end
        if node1.respond_to?(:name) && node1.name.present?
          expect(row["タイトル"]).to eq node1.name
        end
        if node1.respond_to?(:index_name)
          expect(row["一覧用タイトル"]).to eq node1.index_name
        end
        if node1.respond_to?(:order) && node1.order.present?
          expect(row["並び順"]).to eq node1.order.to_s
        end
        if node1.respond_to?(:shortcut)
          expect(row["ショートカット"]).to eq node1&.shortcut
        end
        if node1.respond_to?(:view_route)
          expect(row["既定のモジュール"]).to eq node1&.view_route
        end

        # meta addon
        if node1.respond_to?(:keywords)
          expect(row["キーワード"].to_s).to eq node1&.keywords&.join(", ")
        end
        if node1.respond_to?(:description)
          expect(row["概要"]).to eq node1&.description
        end
        if node1.respond_to?(:summary_html)
          expect(row["サマリー"]).to eq node1&.summary_html
        end

        # list addon
        if node1.respond_to?(:conditions)
          expect(row["検索条件(URL)"].to_s).to eq node1&.conditions&.join(", ")
        end
        if node1.respond_to?(:sort)
          expect(row["リスト並び順"]).to eq node1&.sort
        end
        if node1.respond_to?(:limit)
          expect(row["表示件数"]).to eq node1&.limit&.to_s
        end
        if node1.respond_to?(:new_days)
          expect(row["NEWマーク期間"]).to eq node1&.new_days&.to_s
        end
        if node1.respond_to?(:loop_format)
          expect(row["ループHTML形式"]).to eq node1&.loop_format
        end
        if node1.respond_to?(:upper_html)
          expect(row["上部HTML"]).to eq node1&.upper_html
        end
        if node1.respond_to?(:loop_html)
          expect(row["ループHTML(SHIRASAGI形式)"]).to eq node1&.loop_html
        end
        if node1.respond_to?(:lower_html)
          expect(row["下部HTML"]).to eq node1&.lower_html
        end
        if node1.respond_to?(:loop_liquid)
          expect(row["ループHTML(Liquid形式)"]).to eq node1&.loop_liquid
        end
        if node1.respond_to?(:no_items_display_state)
          expect(row["ページ未検出時表示"]).to eq node1&.no_items_display_state
        end
        if node1.respond_to?(:substitute_html)
          expect(row["代替HTML"]).to eq node1&.substitute_html
        end

        # category addon
        if node1.respond_to?(:st_categories) && node1.st_categories.present?
          expect(row["カテゴリー設定"]).to eq node1.st_categories.map { |cate| "#{cate.name} (#{cate.filename})" }.join(", ")
        end

        # release addon
        if node1.respond_to?(:released_type)
          expect(row["公開日時種別"]).to eq node1&.released_type
        end

        if node1.respond_to?(:state)
          expect(row["ステータス"]).to eq node1&.state
        end

        # cms groups addon
        if node1.respond_to?(:groups) && node1.groups.present?
          expect(row["管理グループ"]).to eq node1.groups.map(&:name).join(", ")
        end
      end
    end
  end
end
