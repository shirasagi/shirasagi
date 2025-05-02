require 'spec_helper'

describe Tasks::Cms, dbscope: :example do
  # cms_site
  let!(:site) { cms_site }

  # site1
  let!(:site1) { create :cms_site_unique }
  let!(:site1_id) { site1.id }
  let!(:site1_path) { site1.path }
  let!(:site1_host) { site1.host }

  let!(:node1_1) { create :article_node_page, cur_site: site1, name: "article" }
  let!(:node1_2) { create :category_node_node, cur_site: site1, filename: "c1", name: "c1" }
  let!(:node1_3) { create :category_node_node, cur_site: site1, filename: "c1/c2", name: "c2" }
  let!(:node1_4) { create :category_node_node, cur_site: site1, filename: "c1/c3", name: "c3" }
  let!(:part1_1) { create :article_part_page, cur_site: site1, cur_node: node1_1 }
  let!(:layout1_1) { create :cms_layout, cur_site: site1, cur_node: node1_1 }
  let!(:page1_1) do
    create :cms_page, cur_site: site1, filename: "index.html", file_ids: [file1_1.id], state: "public"
  end
  let!(:page1_2) do
    create :article_page, cur_site: site1, cur_node: node1_1, file_ids: [file1_2.id], state: "public"
  end
  let!(:file1_1) { create :ss_file, site: site1, state: 'public' }
  let!(:file1_2) { create :ss_file, site: site1, state: 'public' }

  # site2
  let!(:site2) { create :cms_site_unique }
  let!(:site2_id) { site2.id }
  let!(:site2_path) { site2.path }
  let!(:site2_host) { site2.host }

  let!(:node2_1) { create :article_node_page, cur_site: site2, name: "article" }
  let!(:node2_2) { create :category_node_node, cur_site: site2, filename: "c1", name: "c1" }
  let!(:node2_3) { create :category_node_node, cur_site: site2, filename: "c1/c2", name: "c2" }
  let!(:node2_4) { create :category_node_node, cur_site: site2, filename: "c1/c3", name: "c3" }
  let!(:part2_1) { create :article_part_page, cur_site: site2, cur_node: node2_1 }
  let!(:layout2_1) { create :cms_layout, cur_site: site2, cur_node: node2_1 }
  let!(:page2_1) do
    create :cms_page, cur_site: site2, filename: "index.html", file_ids: [file2_1.id], state: "public"
  end
  let!(:page2_2) do
    create :article_page, cur_site: site2, cur_node: node2_1, file_ids: [file2_2.id], state: "public"
  end
  let!(:file2_1) { create :ss_file, site: site2, state: 'public' }
  let!(:file2_2) { create :ss_file, site: site2, state: 'public' }

  context "with site" do
    it do
      expect(SS::Site.all.map(&:host)).to match_array [site.host, site1_host, site2_host]

      expect(Cms::Page.where(site_id: site1_id).count).to eq 2
      expect(Cms::Part.where(site_id: site1_id).count).to eq 1
      expect(Cms::Layout.where(site_id: site1_id).count).to eq 1
      expect(Cms::Node.where(site_id: site1_id).count).to eq 4
      expect(SS::File.where(site_id: site1_id).count).to eq 2
      expect(Fs.exist?(site1_path)).to be_truthy

      expect(Cms::Page.where(site_id: site2_id).count).to eq 2
      expect(Cms::Part.where(site_id: site2_id).count).to eq 1
      expect(Cms::Layout.where(site_id: site2_id).count).to eq 1
      expect(Cms::Node.where(site_id: site2_id).count).to eq 4
      expect(SS::File.where(site_id: site2_id).count).to eq 2
      expect(Fs.exist?(site2_path)).to be_truthy

      ENV['site'] = site1_host
      described_class.remove_site

      expect(SS::Site.all.map(&:host)).to match_array [site.host, site2_host]

      expect(Cms::Page.where(site_id: site1_id).count).to eq 0
      expect(Cms::Part.where(site_id: site1_id).count).to eq 0
      expect(Cms::Layout.where(site_id: site1_id).count).to eq 0
      expect(Cms::Node.where(site_id: site1_id).count).to eq 0
      expect(SS::File.where(site_id: site1_id).count).to eq 0
      expect(Fs.exist?(site1_path)).to be_falsey

      expect(Cms::Page.where(site_id: site2_id).count).to eq 2
      expect(Cms::Part.where(site_id: site2_id).count).to eq 1
      expect(Cms::Layout.where(site_id: site2_id).count).to eq 1
      expect(Cms::Node.where(site_id: site2_id).count).to eq 4
      expect(SS::File.where(site_id: site2_id).count).to eq 2
      expect(Fs.exist?(site2_path)).to be_truthy
    end
  end
end
