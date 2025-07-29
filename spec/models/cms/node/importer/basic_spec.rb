require 'spec_helper'

describe Cms::NodeImporter, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { nil }

  let!(:layout) { create :cms_layout, filename: "more.layout.html" }
  let!(:page_layout) { create :cms_layout, filename: "pages.layout.html" }

  let!(:cate1) { create :category_node_page, name: "安全", filename: "anzen" }
  let!(:cate2) { create :category_node_page, name: "防災", filename: "bosai" }
  let!(:cate3) { create :category_node_page, name: "戸籍", filename: "koseki" }

  let!(:group1) { create :ss_group, name: "シラサギ市", order: 10 }
  let!(:group2) { create :ss_group, name: "シラサギ市/企画政策部", order: 20 }
  let!(:group3) { create :ss_group, name: "シラサギ市/企画政策部/政策課", order: 30 }
  let!(:group4) { create :ss_group, name: "シラサギ市/企画政策部/広報課", order: 40 }
  let!(:group5) { create :ss_group, name: "シラサギ市/危機管理部", order: 50 }
  let!(:group6) { create :ss_group, name: "シラサギ市/危機管理部/管理課", order: 60 }
  let!(:group7) { create :ss_group, name: "シラサギ市/危機管理部/防災課", order: 70 }

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/cms/node/import/basic.csv" }
  let!(:csv_file) { Fs::UploadedFile.create_from_file(csv_path) }
  let!(:ss_file) { create(:ss_file, site: site, user: user, in_file: csv_file) }

  def find_node(filename)
    Cms::Node.site(site).where(filename: filename).first
  end

  before do
    site.group_ids += [group1.id]
    site.update!
  end

  context "article nodes" do
    it "#import" do
      # Check initial node count
      expect(Article::Node::Page.count).to eq 0

      importer = described_class.new(site, node, user)
      importer.import(ss_file)
      expect(Article::Node::Page.count).to eq 1

      # Check the node count after import
      item = find_node("docs")
      expect(item).to be_present
      expect(item.site_id).to eq site.id
      expect(item.parent).to eq false
      expect(item.filename).to eq "docs"
      expect(item.class).to eq Article::Node::Page
      expect(item.name).to eq "title"
      expect(item.index_name).to eq "index_title"
      expect(item.layout.id).to eq layout.id
      expect(item.order).to eq 10
      expect(item.page_layout.id).to eq page_layout.id
      expect(item.shortcut).to eq "show"
      expect(item.view_route).to eq "article/page"
      expect(item.keywords).to eq %w(自治体サンプル 自治体サンプル 自治体サンプル)
      expect(item.description).to eq "概要です"
      expect(item.summary_html).to eq "<div>summary</div>"
      expect(item.conditions).to eq %w(filename1 filename2 filename3)
      expect(item.sort).to eq "order"
      expect(item.limit).to eq 20
      expect(item.new_days).to eq 6
      expect(item.loop_format).to eq "liquid"
      expect(item.upper_html).to eq "<div>upper</div>"
      expect(item.loop_html).to eq "<div>\#{loop}</div>"
      expect(item.lower_html).to eq "<div>lower</div>"
      expect(item.loop_liquid).to eq "<div>{{liquid}}</div>"
      expect(item.no_items_display_state).to eq "show"
      expect(item.substitute_html).to eq "<div>substitute_html</div>"
      expect(item.st_category_ids).to match_array [cate1.id, cate2.id]
      expect(item.released_type).to eq "fixed"
      expect(item.released).to eq Time.zone.parse("2024/6/1 6:01:00")
      expect(item.group_ids).to match_array [group1.id, group2.id, group3.id]
      expect(item.state).to eq "public"
    end
  end
end
