require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy node" do
    let!(:site) { cms_site }
    let!(:layout) { create :cms_layout }
    let!(:node) { create :image_map_node_page, filename: "image-map", name: "image-map" }

    let(:coords1) { [0, 0, 100, 100] }
    let(:coords2) { [10, 10, 110, 110] }
    let(:coords3) { [20, 20, 120, 120] }
    let(:coords4) { [30, 30, 130, 130] }

    let!(:item1) { create(:image_map_page, cur_node: node, coords: coords1, order: 10) }
    let!(:item2) { create(:image_map_page, cur_node: node, coords: coords2, order: 20) }
    let!(:item3) { create(:image_map_page, cur_node: node, coords: coords3, order: 30) }
    let!(:item4) { create(:image_map_page, cur_node: node, coords: coords4, order: 40, state: "closed") }

    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = 'pages'
      task.save!
    end

    describe "copy cms/node" do
      before do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        expect(Job::Log.count).to eq 1
        #Job::Log.first.tap do |log|
        #  expect(log.logs).not_to include(include('WARN'))
        #  expect(log.logs).not_to include(include('ERROR'))
        #  expect(log.logs).to include(/INFO -- : .* Completed Job/)
        #end

        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        dest_layout = Cms::Layout.site(dest_site).find_by(filename: layout.filename)

        ImageMap::Node::Page.site(dest_site).find_by(filename: node.filename).tap do |dest_node|
          expect(dest_node.name).to eq node.name
          expect(dest_node.image).to be_present
          expect(dest_node.image.site.id).to eq dest_site.id
          expect(dest_node.image.owner_item.id).to eq dest_node.id
          expect(Fs.binread(dest_node.image.path)).to eq Fs.binread(node.image.path)
        end

        ImageMap::Page.site(dest_site).find_by(filename: item1.filename).tap do |dest_item1|
          expect(dest_item1.name).to eq item1.name
          expect(dest_item1.coords).to eq item1.coords
          expect(dest_item1.order).to eq item1.order
          expect(dest_item1.state).to eq item1.state
        end

        ImageMap::Page.site(dest_site).find_by(filename: item2.filename).tap do |dest_item2|
          expect(dest_item2.name).to eq item2.name
          expect(dest_item2.coords).to eq item2.coords
          expect(dest_item2.order).to eq item2.order
          expect(dest_item2.state).to eq item2.state
        end

        ImageMap::Page.site(dest_site).find_by(filename: item3.filename).tap do |dest_item3|
          expect(dest_item3.name).to eq item3.name
          expect(dest_item3.coords).to eq item3.coords
          expect(dest_item3.order).to eq item3.order
          expect(dest_item3.state).to eq item3.state
        end

        ImageMap::Page.site(dest_site).find_by(filename: item4.filename).tap do |dest_item4|
          expect(dest_item4.name).to eq item4.name
          expect(dest_item4.coords).to eq item4.coords
          expect(dest_item4.order).to eq item4.order
          expect(dest_item4.state).to eq item4.state
        end
      end
    end
  end
end
