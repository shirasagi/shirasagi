require 'spec_helper'

describe Sitemap::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :sitemap_node_base }
  it_behaves_like "cms_node#spec"
end

describe Sitemap::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :sitemap_node_page }
  it_behaves_like "cms_node#spec"
end
