require 'spec_helper'

describe Uploader::Node::Base do
  subject(:model) { Uploader::Node::Base }
  subject(:factory) { :uploader_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Uploader::Node::File do
  subject(:model) { Uploader::Node::File }
  subject(:factory) { :uploader_node_file }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
