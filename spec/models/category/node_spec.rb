require 'spec_helper'

describe Category::Node::Base do
  subject(:model) { Category::Node::Base }
  subject(:factory) { :category_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Category::Node::Node do
  subject(:model) { Category::Node::Node }
  subject(:factory) { :category_node_node }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Category::Node::Page do
  subject(:model) { Category::Node::Page }
  subject(:factory) { :category_node_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
