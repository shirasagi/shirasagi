require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy node" do
    let(:site) { cms_site }
    let(:layout) { create :cms_layout, cur_site: site }
    let(:task) do
      create(
        :copy_nodes_task, site_id: site.id, node_id: node.id,
        target_node_name: target_node_name, target_node_filename: target_node_filename
      )
    end
    let!(:node1) { create :cms_node, cur_site: site, layout: layout }
    let!(:node2) { create :cms_node, cur_site: site, cur_node: node1, layout: layout, basename: "node2" }
    let!(:node3) { create :article_node_page, cur_site: site, cur_node: node2, layout: layout, basename: "node3" }
    let!(:other_node) { create :cms_node, cur_site: site }

    describe "copy nodes on top level" do
      let(:target_node_name) { unique_id }
      let(:target_node_filename) { unique_id }

      before do
        expect do
          job = Cms::Node::CopyNodesJob.bind(site_id: site.id, node_id: node1.id)
          job.perform_now(target_node_name: target_node_name, target_node_filename: target_node_filename)
        end.to output(include(node3.filename)).to_stdout
      end

      it "coped nodes and it refer original layout id ,and also child nodes" do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).not_to include(include('コピーに失敗しました'))
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        copied_node = Cms::Node.site(site).where(filename: /^#{target_node_filename}\//, depth: 3).first
        expect(copied_node.filename).to eq "#{target_node_filename}/node2/node3"
        expect(copied_node.layout_id).to eq layout.id
      end
    end

    describe "copy nodes under other node" do
      let(:target_node_name) { node1.name }
      let(:target_node_filename) { "#{other_node.filename}/node_name" }

      before do
        expect do
          job = Cms::Node::CopyNodesJob.bind(site_id: site.id, node_id: node1.id)
          job.perform_now(target_node_name: target_node_name, target_node_filename: target_node_filename)
        end.to output(include(node3.filename)).to_stdout
      end

      it "copied" do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).not_to include(include('コピーに失敗しました'))
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        copied_node = Cms::Node.site(site).where(filename: /^#{target_node_filename}\//, depth: 4).first
        expect(copied_node.filename).to eq "#{target_node_filename}/node2/node3"
      end
    end
  end
end
