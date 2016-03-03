require 'spec_helper'

describe Inquiry::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :inquiry_node_base }
  it_behaves_like "cms_node#spec"
end

describe Inquiry::Node::Form, type: :model, dbscope: :example do
  let(:item) { create :inquiry_node_form }
  it_behaves_like "cms_node#spec"
end
