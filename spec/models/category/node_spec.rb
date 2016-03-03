require 'spec_helper'

describe Category::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :category_node_base }
  it_behaves_like "cms_node#spec"
end

describe Category::Node::Node, type: :model, dbscope: :example do
  let(:item) { create :category_node_node }
  it_behaves_like "cms_node#spec"
end

describe Category::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :category_node_page }
  it_behaves_like "cms_node#spec"
end
