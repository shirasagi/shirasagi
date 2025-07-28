require 'spec_helper'

describe Cms::Node::ReleaseJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node1) { create :cms_node_node, cur_site: site }
  let!(:node2) { create :cms_node_node, cur_site: site }

  describe "#perform" do
    before do
      now = Time.zone.now.advance(days: -1)
      Timecop.travel(10.days.ago) do
        node1.release_date = now
        node2.close_date = now
        node1.save
        node2.save
      end

      expect(node1.state).to eq "ready"
      expect(node2.state).to eq "public"
      expect { described_class.bind(site_id: site.id).perform_now }.to output(include(node1.name)).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      node1.reload
      node2.reload
      expect(node1.state).to eq "public"
      expect(node2.state).to eq "closed"
    end
  end
end
