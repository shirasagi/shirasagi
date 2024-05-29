require 'spec_helper'

describe Sitemap::Page do
  subject(:model) { described_class }
  subject(:factory) { :sitemap_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    let(:node) { create :sitemap_node_page }
    let(:item) { create :sitemap_page, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.sitemap_page_path(site: item.site, cid: node, id: item.id) }

    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
  end
end
