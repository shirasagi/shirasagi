require 'spec_helper'

describe Faq::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :faq_node_base }
  it_behaves_like "cms_node#spec"
end

describe Faq::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :faq_node_page }
  it_behaves_like "cms_node#spec"
end

describe Faq::Node::Search, type: :model, dbscope: :example do
  let(:item) { create :faq_node_search }
  it_behaves_like "cms_node#spec"
end
