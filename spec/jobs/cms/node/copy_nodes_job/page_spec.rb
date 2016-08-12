require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy page" do
    let(:site) { cms_site }
    let(:target_node_name) { unique_id }
    let(:task) { create :copy_nodes_task, target_node_name: target_node_name, site_id: site.id, node_id: node.id }
    let!(:file) { create :cms_file, site_id: site.id }
    let!(:node) { create :cms_node, cur_site: site }
    let!(:article_page) do
      create :article_page,
      cur_site: site,
      cur_node: node,
      filename: "#{node.filename}/page",
      file_ids: [file.id]
    end

    describe "copy page which is located under a node" do

      before do
        perform_enqueued_jobs do
          Cms::Node::CopyNodesJob.bind( {site_id: site.id, node_id: node.id} )
          .perform_now( {target_node_name: target_node_name} )
        end
      end

      it "was copied with original file_ids under target node" do
        copied_node = Cms::Node.site(site).find_by(filename: target_node_name)
        copied_page = Cms::Page.site(site).where(filename: /^#{target_node_name}\//).first
        expect(copied_node.filename).to eq target_node_name
        expect(copied_page.filename).to eq "#{target_node_name}/page.html"
        expect(copied_page.file_ids).to include file.id
      end
    end
  end
end
