require 'spec_helper'

describe Cms::Node, type: :model, dbscope: :example do
  let(:item) { create :cms_node }
  it_behaves_like "cms_node#spec"
end

describe Cms::Node::Base do
end

describe Cms::Node::Node do
  let(:item) { create :cms_node_node }
  it_behaves_like "cms_node#spec"
end

describe Cms::Node::Page do
  let(:item) { create :cms_node_page }
  it_behaves_like "cms_node#spec"
end
