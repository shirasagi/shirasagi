require 'spec_helper'

describe Cms::Agents::Nodes::ArchiveController, type: :request, dbscope: :example do
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node1) { create :article_node_page, cur_site: site, layout: layout }
  let!(:node1_1) { create :cms_node_archive, cur_site: site, cur_node: node1, layout: layout }

  describe "#index" do
    it do
      get node1_1.full_url
      expect(response.status).to eq 302
      expect(response.location).to eq "#{node1_1.full_url}#{today.strftime('%Y%m')}/"
    end
  end
end
