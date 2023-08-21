require 'spec_helper'

describe Urgency::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :urgency_node_base }
  it_behaves_like "cms_node#spec"
end

describe Urgency::Node::Layout, type: :model, dbscope: :example do
  let(:item) { create :urgency_node_layout }
  it_behaves_like "cms_node#spec"
end
