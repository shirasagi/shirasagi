require 'spec_helper'

describe Sitemap::Node::Base do
  subject(:model) { Sitemap::Node::Base }
  subject(:factory) { :sitemap_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Sitemap::Node::Page do
  subject(:model) { Sitemap::Node::Page }
  subject(:factory) { :sitemap_node_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
