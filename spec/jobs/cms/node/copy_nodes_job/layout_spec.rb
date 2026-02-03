require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy layout" do
    let(:site) { cms_site }
    let(:target_node_name) { unique_id }
    let(:target_node_filename) { unique_id }
    let(:task) do
      create(
        :copy_nodes_task, site_id: site.id, node_id: node.id,
        target_node_name: target_node_name, target_node_filename: target_node_filename
      )
    end
    let!(:node) { create :cms_node, cur_site: site }
    let!(:layout) { create :cms_layout, cur_site: site, cur_node: node, basename: "layout" }

    describe "copy layout which is located under a node" do
      before do
        expect do
          job = Cms::Node::CopyNodesJob.bind(site_id: site.id, node_id: node.id)
          job.perform_now(target_node_name: target_node_name, target_node_filename: target_node_filename)
        end.to output(include(layout.filename)).to_stdout
      end

      it "copied layout filename was changed " do
        copied_layout = Cms::Layout.site(site).where(filename: /^#{target_node_filename}\//).first
        expect(copied_layout.filename).to eq "#{target_node_filename}/layout.layout.html"
      end
    end
  end
end
