require 'spec_helper'

describe Inquiry::Node::Base do
  subject(:model) { Inquiry::Node::Base }
  subject(:factory) { :inquiry_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Inquiry::Node::Form do
  subject(:model) { Inquiry::Node::Form }
  subject(:factory) { :inquiry_node_form }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
