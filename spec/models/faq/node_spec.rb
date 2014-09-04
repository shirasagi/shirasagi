require 'spec_helper'

describe Faq::Node::Base do
  subject(:model) { Faq::Node::Base }
  subject(:factory) { :faq_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Faq::Node::Page do
  subject(:model) { Faq::Node::Page }
  subject(:factory) { :faq_node_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Faq::Node::Search do
  subject(:model) { Faq::Node::Search }
  subject(:factory) { :faq_node_search }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
