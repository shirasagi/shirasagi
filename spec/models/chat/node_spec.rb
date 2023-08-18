require 'spec_helper'

describe Chat::Node::Bot, type: :model, dbscope: :example do
  let(:item) { create :chat_node_bot }
  it_behaves_like "cms_node#spec"
end
