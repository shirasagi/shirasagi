require 'spec_helper'

describe Ads::Banner do
  subject(:model) { Ads::Banner }
  subject(:factory) { :ads_banner }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    let(:node) { create :article_node_page }
    let(:item) { create :ads_banner, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.ads_banner_path(site: item.site, cid: node, id: item.id) }

    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
    it { expect(item.count_url).not_to eq nil }
  end
end
