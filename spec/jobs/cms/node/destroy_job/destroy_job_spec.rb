require 'spec_helper'

describe Cms::Node::DestroyJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node1) { create :cms_node_node, cur_site: site }
  let!(:node2) { create :cms_node_node, cur_site: site }

  describe "#perform" do
    before do
      job = described_class.bind(site_id: site.id, user_id: cms_user.id)
      expect { ss_perform_now(job, [node1.id]) }.to output(include(node1.name)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(Cms::Node.count).to eq 1
      expect(Cms::Node.first.id).to eq node2.id
    end
  end
end
