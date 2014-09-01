require 'spec_helper'

describe Urgency::Node::Base do
  subject(:model) { Urgency::Node::Base }
  subject(:factory) { :urgency_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Urgency::Node::Layout do
  subject(:model) { Urgency::Node::Layout }
  subject(:factory) { :urgency_node_layout }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
