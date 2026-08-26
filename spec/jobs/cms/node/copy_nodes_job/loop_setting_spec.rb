require 'spec_helper'

describe Cms::Node::CopyNodesJob, dbscope: :example do
  describe "copy node which refers shared loop setting" do
    let(:site) { cms_site }
    let(:layout) { create :cms_layout, cur_site: site }
    let!(:loop_setting) { create :cms_loop_setting, cur_site: site }
    let!(:node1) { create :cms_node, cur_site: site, layout: layout }
    let!(:node2) do
      create :article_node_page, cur_site: site, cur_node: node1, layout: layout, basename: "node2",
        loop_setting_id: loop_setting.id
    end

    let(:target_node_name) { unique_id }
    let(:target_node_index_name) { unique_id }
    let(:target_node_filename) { unique_id }

    before do
      expect do
        job = Cms::Node::CopyNodesJob.bind(site_id: site.id, node_id: node1.id)
        job.perform_now(
          target_node_name: target_node_name, target_node_index_name: target_node_index_name,
          target_node_filename: target_node_filename)
      end.to output(include(node2.filename)).to_stdout
    end

    it "copied node refers the same loop setting" do
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).not_to include(include('コピーに失敗しました'))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      copied_node = Cms::Node.site(site).where(filename: "#{target_node_filename}/node2").first
      expect(copied_node).to be_present
      expect(copied_node.loop_setting_id).to eq loop_setting.id
    end
  end
end
