require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

  describe "#attributes" do
    subject(:item) { create :article_page, cur_node: node }

    it { expect(item.becomes_with_route).not_to be_nil }
    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to be_nil }
    it { expect(item.path).not_to be_nil }
    it { expect(item.url).not_to be_nil }
    it { expect(item.full_url).not_to be_nil }
    it { expect(item.parent).to eq node }
  end

  describe "shirasagi-442" do
    subject { create :article_page, cur_node: node, html: "   <p>あ。&rarr;い</p>\r\n   " }
    its(:summary) { is_expected.to eq "あ。→い" }
  end
end
