require 'spec_helper'

describe Uploader::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :uploader_node_base }
  it_behaves_like "cms_node#spec"
end

describe Uploader::Node::File do
  let(:item) { create :uploader_node_file }
  it_behaves_like "cms_node#spec"
end
