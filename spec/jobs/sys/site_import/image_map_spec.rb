require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:layout) { create :cms_layout, cur_site: source_site }
  let!(:node) { create :image_map_node_page, cur_site: source_site }

  let(:coords1) { [0, 0, 100, 100] }
  let(:coords2) { [10, 10, 110, 110] }
  let(:coords3) { [20, 20, 120, 120] }
  let(:coords4) { [30, 30, 130, 130] }

  let!(:item1) do
    create(:image_map_page, cur_site: source_site, cur_node: node, coords: coords1, order: 10)
  end
  let!(:item2) do
    create(:image_map_page, cur_site: source_site, cur_node: node, coords: coords2, order: 20)
  end
  let!(:item3) do
    create(:image_map_page, cur_site: source_site, cur_node: node, coords: coords3, order: 30)
  end
  let!(:item4) do
    create(:image_map_page, cur_site: source_site, cur_node: node, coords: coords4, order: 40, state: "closed")
  end

  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = ::Sys::SiteExportJob.new
      job.bind("site_id" => source_site.id).perform
      output_zip = job.instance_variable_get(:@output_zip)

      output_zip
    ensure
      Sys::SiteExportJob.export_root = save_export_root
    end
  end

  describe "#perform" do
    let!(:destination_site) { create :cms_site_unique }

    let(:dest_node) { ImageMap::Node::Page.site(destination_site).where(filename: node.filename).first }
    let(:dest_item1) { ImageMap::Page.site(destination_site).where(filename: item1.filename).first }
    let(:dest_item2) { ImageMap::Page.site(destination_site).where(filename: item2.filename).first }
    let(:dest_item3) { ImageMap::Page.site(destination_site).where(filename: item3.filename).first }
    let(:dest_item4) { ImageMap::Page.site(destination_site).where(filename: item4.filename).first }

    it do
      job = ::Sys::SiteImportJob.new
      job.bind("site_id" => destination_site.id).perform(file_path)

      dest_node
      dest_item1
      dest_item2
      dest_item3
      dest_item4

      expect(dest_node).to be_present
      expect(dest_item1).to be_present
      expect(dest_item2).to be_present
      expect(dest_item3).to be_present
      expect(dest_item4).to be_present

      expect(dest_node.name).to eq node.name
      expect(dest_node.image).to be_present
      expect(dest_node.image.site.id).to eq destination_site.id
      expect(dest_node.image.owner_item.id).to eq dest_node.id
      expect(Fs.binread(dest_node.image.path)).to eq Fs.binread(node.image.path)

      expect(dest_item1.name).to eq item1.name
      expect(dest_item1.coords).to eq item1.coords
      expect(dest_item1.order).to eq item1.order
      expect(dest_item1.state).to eq item1.state

      expect(dest_item2.name).to eq item2.name
      expect(dest_item2.coords).to eq item2.coords
      expect(dest_item2.order).to eq item2.order
      expect(dest_item2.state).to eq item2.state

      expect(dest_item3.name).to eq item3.name
      expect(dest_item3.coords).to eq item3.coords
      expect(dest_item3.order).to eq item3.order
      expect(dest_item3.state).to eq item3.state

      expect(dest_item4.name).to eq item4.name
      expect(dest_item4.coords).to eq item4.coords
      expect(dest_item4.order).to eq item4.order
      expect(dest_item4.state).to eq item4.state
    end
  end
end
