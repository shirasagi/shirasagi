require 'spec_helper'

describe Ads::Node::Banner, type: :model, dbscope: :example do
  let(:item) { create :ads_node_banner }
  it_behaves_like "cms_node#spec"
end
