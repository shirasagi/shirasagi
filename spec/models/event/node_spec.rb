require 'spec_helper'

describe Event::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :event_node_base }
  it_behaves_like "cms_node#spec"
end

describe Event::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :event_node_page }
  it_behaves_like "cms_node#spec"
end
