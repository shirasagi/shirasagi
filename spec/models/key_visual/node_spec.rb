require 'spec_helper'

describe KeyVisual::Node::Image do
  subject(:model) { KeyVisual::Node::Image }
  subject(:factory) { :key_visual_node_image }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
