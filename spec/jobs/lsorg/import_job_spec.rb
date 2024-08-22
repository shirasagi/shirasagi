require 'spec_helper'

describe Lsorg::ImportGroupsJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create :cms_layout, site: site }
  let!(:node) { create :lsorg_node_node, layout: layout, group_ids: [site.id] }

  let!(:g1) { create :cms_group, name: "A", order: 10, basename: "a" }
  let!(:g1_1) { create :cms_group, name: "A/B", order: 20, basename: "b" }
  let!(:g1_1_1) { create :cms_group, name: "A/B/C", order: 30, basename: "c" }
  let!(:g1_1_2) { create :cms_group, name: "A/B/D", order: 40, basename: "d" }
  let!(:g1_2) { create :cms_group, name: "A/E", order: 50, basename: "e" }
  let!(:g1_2_1) { create :cms_group, name: "A/E/F", order: 60, basename: "f" }
  let!(:g1_2_2) { create :cms_group, name: "A/E/G/H", order: 70, basename: "h" }
  let!(:g1_3) { create :cms_group, name: "A/I/J", order: 80, basename: "j" }

  let!(:g2) { create :cms_group, name: "K", order: 90, basename: "k" }
  let!(:g2_1) { create :cms_group, name: "K/L", order: 100, basename: "l" }
  let!(:g2_2) { create :cms_group, name: "K/M", order: 110, basename: "m" }

  def expect_node(filename, group_id, state)
    group = Cms::Group.unscoped.find(group_id)
    item = Lsorg::Node::Page.site(site).where(filename: "#{node.filename}/#{filename}").first

    expect(item).to be_present
    expect(item.name).to eq group.trailing_name
    expect(item.filename).to eq "#{node.filename}/#{filename}"
    expect(item.layout_id).to eq node.layout_id
    expect(item.order).to eq group.order
    expect(item.page_group_id).to eq group.id
    expect(item.group_ids).to match_array node.group_ids
    expect(item.state).to eq state
  end

  describe "#perform" do
    context "roots g1, g2" do
      before do
        node.root_group_ids = [g1.id, g2.id]
        node.update!
      end

      context "rename groups" do
        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 11
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11

          ## 変更1回目
          # グループ名変更
          g1.name = "N"
          g1.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 11
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11

          ## 変更2回目
          # ファイル名変更
          g1.basename = "n"
          g1.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("n", g1.id, "public")
          expect_node("n/b", g1_1.id, "public")
          expect_node("n/b/c", g1_1_1.id, "public")
          expect_node("n/b/d", g1_1_2.id, "public")
          expect_node("n/e", g1_2.id, "public")
          expect_node("n/e/f", g1_2_1.id, "public")
          expect_node("n/e/h", g1_2_2.id, "public")
          expect_node("n/j", g1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 11
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11
        end
      end

      context "move groups" do
        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 11
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11

          ## 変更1回目
          # 新設
          g1_1_3 = create(:cms_group, name: "A/B/N", order: 120, basename: "n")

          # 移動
          g1_2.name = "A/B/E"
          g1_2.update!

          # 廃止
          g1_2_2.disable

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/b/e", g1_2.id, "public")
          expect_node("a/b/e/f", g1_2_1.id, "public")
          expect_node("a/b/e/h", g1_2_2.id, "closed")
          expect_node("a/j", g1_3.id, "public")
          expect_node("a/b/n", g1_1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 12
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11

          ## 変更2回目
          # 統合 (g_1_1 と g1_1_2 が統合され g1_1_2 が廃止)
          g1_1_2.disable

          # 分割 (g1_1_3 が g1_1_3 と g1_1_4 に分割)
          g1_1_4 = create(:cms_group, name: "A/B/O", order: 130, basename: "o")

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "closed")
          expect_node("a/b/e", g1_2.id, "public")
          expect_node("a/b/e/f", g1_2_1.id, "public")
          expect_node("a/b/e/h", g1_2_2.id, "closed")
          expect_node("a/j", g1_3.id, "public")
          expect_node("a/b/n", g1_1_3.id, "public")
          expect_node("a/b/o", g1_1_4.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 13
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11
        end

        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          ## 変更1回目
          # 移動
          g2.name = "A/K"
          g2.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")
          expect_node("a/k", g2.id, "public")
          expect_node("a/k/l", g2_1.id, "public")
          expect_node("a/k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 11
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11

          ## 変更2回目
          # 移動
          g2.name = "K"
          g2.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/l", g2_1.id, "public")
          expect_node("k/m", g2_2.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 11
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 11
        end
      end
    end

    context "roots g1_1, g1_2, g2_1, (g1_1_1)" do
      before do
        node.root_group_ids = [g1_1.id, g1_1_1.id, g1_2.id, g2_1.id]
        node.update!
      end

      context "rename groups" do
        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("b", g1_1.id, "public")
          expect_node("b/c", g1_1_1.id, "public")
          expect_node("b/d", g1_1_2.id, "public")
          expect_node("e", g1_2.id, "public")
          expect_node("e/f", g1_2_1.id, "public")
          expect_node("e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 7
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 7

          ## 変更1回目
          # グループ名変更
          g1_1.name = "N"
          g1_1.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("b", g1_1.id, "public")
          expect_node("b/c", g1_1_1.id, "public")
          expect_node("b/d", g1_1_2.id, "public")
          expect_node("e", g1_2.id, "public")
          expect_node("e/f", g1_2_1.id, "public")
          expect_node("e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 7
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 7

          ## 変更2回目
          # ファイル名変更
          g1_1.basename = "n"
          g1_1.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("n", g1_1.id, "public")
          expect_node("n/c", g1_1_1.id, "public")
          expect_node("n/d", g1_1_2.id, "public")
          expect_node("e", g1_2.id, "public")
          expect_node("e/f", g1_2_1.id, "public")
          expect_node("e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 7
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 7
        end
      end

      context "move groups" do
        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("b", g1_1.id, "public")
          expect_node("b/c", g1_1_1.id, "public")
          expect_node("b/d", g1_1_2.id, "public")
          expect_node("e", g1_2.id, "public")
          expect_node("e/f", g1_2_1.id, "public")
          expect_node("e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 7
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 7

          ## 変更1回目
          # 移動
          g1.name = "K/A"
          g1.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("b", g1_1.id, "public")
          expect_node("b/c", g1_1_1.id, "public")
          expect_node("b/d", g1_1_2.id, "public")
          expect_node("e", g1_2.id, "public")
          expect_node("e/f", g1_2_1.id, "public")
          expect_node("e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")
        end

        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("b", g1_1.id, "public")
          expect_node("b/c", g1_1_1.id, "public")
          expect_node("b/d", g1_1_2.id, "public")
          expect_node("e", g1_2.id, "public")
          expect_node("e/f", g1_2_1.id, "public")
          expect_node("e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 7
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 7

          ## 変更1回目
          # 移動
          g1_2.name = "A/B/E"
          g1_2.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("b", g1_1.id, "public")
          expect_node("b/c", g1_1_1.id, "public")
          expect_node("b/d", g1_1_2.id, "public")
          expect_node("b/e", g1_2.id, "public")
          expect_node("b/e/f", g1_2_1.id, "public")
          expect_node("b/e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 7
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 7

          ## 変更2回目
          # 移動
          g1_1_1.name = "C"
          g1_1_1.update!

          g1_1_2.name = "D"
          g1_1_2.update!

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("b", g1_1.id, "public")
          expect_node("b/d", g1_1_2.id, "closed")
          expect_node("b/e", g1_2.id, "public")
          expect_node("b/e/f", g1_2_1.id, "public")
          expect_node("b/e/h", g1_2_2.id, "public")
          expect_node("l", g2_1.id, "public")
          expect_node("c", g1_1_1.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 7
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 6
        end
      end
    end

    context "no roots" do
      it do
        Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})
        expect(Lsorg::Node::Page.count).to eq 0
      end
    end

    context "invalid case" do
      context "exist non-related node" do
        before do
          node.root_group_ids = [g1.id, g2.id]
          node.update!
        end

        let!(:node2) do
          create(:lsorg_node_page, filename: "#{node.filename}/#{g1.basename}/#{g1_1.basename}",
            layout: layout, group_ids: [site.id])
        end
        let!(:node3) do
          create(:cms_node_page, filename: "#{node.filename}/#{g2.basename}/#{g2_1.basename}",
            layout: layout, group_ids: [site.id])
        end

        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")
          expect_node("k", g2.id, "public")
          expect_node("k/m", g2_2.id, "public")

          node2.reload
          expect(node2.state).to eq "closed"

          expect(Lsorg::Node::Page.site(site).count).to eq 8
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 7
        end
      end

      context "swap parent and child" do
        before do
          node.root_group_ids = [g1.id]
          node.update!
        end

        it do
          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/b", g1_1.id, "public")
          expect_node("a/b/c", g1_1_1.id, "public")
          expect_node("a/b/d", g1_1_2.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 8
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 8

          ## 変更1回目
          # 移動
          g1_1_1.name = "tmp"
          g1_1_1.basename = "tmp"
          g1_1_1.update!

          g1_1.name = "tmp/C"
          g1_1.basename = "c"
          g1_1.update!

          g1_1_1.name = "A/B"
          g1_1_1.basename = "b"
          g1_1_1.update!

          g1_1.reload
          g1_1_1.reload

          Lsorg::ImportGroupsJob.bind({ site_id: site.id, node_id: node.id }).perform_now({})

          expect_node("a", g1.id, "public")
          expect_node("a/e", g1_2.id, "public")
          expect_node("a/e/f", g1_2_1.id, "public")
          expect_node("a/e/h", g1_2_2.id, "public")
          expect_node("a/j", g1_3.id, "public")

          expect(Lsorg::Node::Page.site(site).count).to eq 8
          expect(Lsorg::Node::Page.site(site).and_public.count).to eq 5
        end
      end
    end
  end
end
