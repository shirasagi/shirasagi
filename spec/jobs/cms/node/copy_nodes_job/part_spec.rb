require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy part" do
    let(:site) { cms_site }
    let(:target_node_name) { unique_id }
    let(:task) { create :copy_nodes_task, target_node_name: target_node_name, site_id: site.id, node_id: node.id }
    let!(:node) { create :cms_node, cur_site: site }
    let!(:part) do
      lower_html = "<div class=\"feed\"><a class=\"rss\" href=\"/#{node.filename}/rss.xml\">RSS</a>"
      create :article_part_page, cur_site: site, cur_node: node, basename: "part", lower_html: lower_html
    end

    describe "copy part which is located under a node" do
      before do
        job_class = Cms::Node::CopyNodesJob.bind(site_id: site.id, node_id: node.id)
        ss_perform_now(job_class, target_node_name: target_node_name)
      end

      it "html element which has original node name was overwritten" do
        copied_part = Cms::Part.site(site).where(filename: /^#{target_node_name}\//).first
        expect(copied_part.filename).to eq "#{target_node_name}/part.part.html"
        expect(copied_part.lower_html).not_to include node.filename.to_s
        expect(copied_part.lower_html).to include target_node_name.to_s
      end
    end
  end
end
