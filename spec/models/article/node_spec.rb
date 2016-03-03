require 'spec_helper'

describe Article::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :article_node_base }
  it_behaves_like "cms_node#spec"
end

describe Article::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :article_node_page }
  it_behaves_like "cms_node#spec"
end
