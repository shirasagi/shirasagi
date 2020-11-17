require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy page" do
    let(:site) { cms_site }
    let(:target_node_name) { unique_id }
    let(:task) { create :copy_nodes_task, target_node_name: target_node_name, site_id: site.id, node_id: node.id }
    let!(:file) { create :cms_file, site_id: site.id }
    let!(:node) { create :article_node_page, cur_site: site }
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

      it "created new copied file under target node" do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).not_to include(include('コピーに失敗しました'))
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        copied_node = Cms::Node.site(site).find_by(filename: target_node_name)
        copied_page = Cms::Page.site(site).where(filename: /^#{target_node_name}\//).first
        expect(copied_node.filename).to eq target_node_name
        expect(copied_page.filename).to eq "#{target_node_name}/page.html"
        expect(copied_page.file_ids).not_to include file.id
      end
    end
  end
end
