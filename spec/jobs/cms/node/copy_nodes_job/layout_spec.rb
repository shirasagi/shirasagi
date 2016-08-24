require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy layout" do
    let(:site) { cms_site }
    let(:target_node_name) { unique_id }
    let(:task) { create :copy_nodes_task, target_node_name: target_node_name, site_id: site.id, node_id: node.id }
    let!(:node) { create :cms_node, cur_site: site }
    let!(:layout) { create :cms_layout , filename: "#{node.filename}/layout" }

    describe "copy layout which is located under a node" do

      before do
        perform_enqueued_jobs do
          Cms::Node::CopyNodesJob.bind( {site_id: site.id, node_id: node.id} )
          .perform_now( {target_node_name: target_node_name} )
        end
      end

      it "copied layout filename was changed " do
        copied_layout = Cms::Layout.site(site).where(filename: /^#{target_node_name}\//).first
        expect(copied_layout.filename).to eq "#{target_node_name}/layout.layout.html"
      end
    end
  end
end
