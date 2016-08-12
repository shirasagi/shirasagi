require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy node" do
    let(:site) { cms_site }
    let(:layout) { create :cms_layout, cur_site: site }
    let(:task) { create :copy_nodes_task, target_node_name: target_node_name, site_id: site.id, node_id: node.id }
    let!(:node1) { create :cms_node, cur_site: site, layout_id: layout.id }
    let!(:node2) { create :cms_node, cur_site: site, layout_id: layout.id, filename: "#{node1.filename}/node2" }
    let!(:node3) { create :cms_node, cur_site: site, layout_id: layout.id, filename: "#{node1.filename}/node2/node3" }
    let!(:other_node) { create :cms_node, cur_site: site }

    describe "copy nodes on top level" do
      let(:target_node_name) { unique_id }
      before do
        perform_enqueued_jobs do
          Cms::Node::CopyNodesJob.bind( {site_id: site.id, node_id: node1.id} )
          .perform_now( {target_node_name: target_node_name} )
        end
      end

      it "coped nodes and it refer original layout id ,and alse child nodes" do
        copied_node = Cms::Node.site(site).where(filename: /^#{target_node_name}\//, depth: 3).first
        expect(copied_node.filename).to eq "#{target_node_name}/node2/node3"
        expect(copied_node.layout_id).to eq layout.id
      end
    end

    describe "copy nodes under other node" do
      let(:target_node_name) { "#{other_node.filename}/node_name"}
      before do
        perform_enqueued_jobs do
          Cms::Node::CopyNodesJob.bind( {site_id: site.id, node_id: node1.id} )
          .perform_now( {target_node_name: target_node_name} )
        end
      end
      it "copied" do
        copied_node = Cms::Node.site(site).where(filename: /^#{target_node_name}\//, depth: 4).first
        expect(copied_node.filename).to eq "#{target_node_name}/node2/node3"
      end
    end
  end
end
