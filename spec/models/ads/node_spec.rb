require 'spec_helper'

describe Ads::Node::Banner do
  subject(:model) { Ads::Node::Banner }
  subject(:factory) { :ads_node_banner }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
