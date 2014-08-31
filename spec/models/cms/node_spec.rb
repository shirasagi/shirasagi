require 'spec_helper'

describe Cms::Node do
  subject(:model) { Cms::Node }
  subject(:factory) { :cms_node }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }

    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parents).not_to eq nil }
    it { expect(item.nodes).not_to eq nil }
    it { expect(item.children).not_to eq nil }
    it { expect(item.pages).not_to eq nil }
    it { expect(item.parts).not_to eq nil }
    it { expect(item.layouts).not_to eq nil }
  end
end

describe Cms::Node::Base do
  subject(:model) { Cms::Node::Base }
  subject(:factory) { :cms_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Cms::Node::Node do
  subject(:model) { Cms::Node::Node }
  subject(:factory) { :cms_node_node }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Cms::Node::Page do
  subject(:model) { Cms::Node::Page }
  subject(:factory) { :cms_node_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
