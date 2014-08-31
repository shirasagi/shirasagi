require 'spec_helper'

describe Article::Node::Base do
  subject(:model) { Article::Node::Base }
  subject(:factory) { :article_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Article::Node::Page do
  subject(:model) { Article::Node::Page }
  subject(:factory) { :article_node_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
