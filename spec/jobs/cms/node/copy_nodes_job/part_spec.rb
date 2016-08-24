require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy part" do
    let(:site) { cms_site }
    let(:target_node_name) { unique_id }
    let(:task) { create :copy_nodes_task, target_node_name: target_node_name, site_id: site.id, node_id: node.id }
    let!(:node) { create :cms_node, cur_site: site }
    let!(:part) do
      create :article_part_page,
      cur_site: site,
      filename: "#{node.filename}/part",
      lower_html: "<div class=\"feed\"><a class=\"rss\" href=\"/#{node.filename}/rss.xml\">RSS</a>"
    end

    describe "copy part which is located under a node" do

      before do
        perform_enqueued_jobs do
          Cms::Node::CopyNodesJob.bind( {site_id: site.id, node_id: node.id} )
          .perform_now( {target_node_name: target_node_name} )
        end
      end

      it "html element which has original node name was overwritten" do
        copied_part = Cms::Part.site(site).where(filename: /^#{target_node_name}\//).first.becomes_with_route
        expect(copied_part.filename).to eq "#{target_node_name}/part.part.html"
        expect(copied_part.lower_html).not_to include node.filename.to_s
        expect(copied_part.lower_html).to include target_node_name.to_s
      end
    end
  end
end
