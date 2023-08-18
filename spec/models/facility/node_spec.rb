require 'spec_helper'

describe Facility::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :facility_node_base }
  it_behaves_like "cms_node#spec"
end

describe Facility::Node::Node, type: :model, dbscope: :example do
  let(:item) { create :facility_node_node }
  it_behaves_like "cms_node#spec"
end

describe Facility::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :facility_node_page }
  it_behaves_like "cms_node#spec"
end

describe Facility::Node::Search, type: :model, dbscope: :example do
  let(:item) { create :facility_node_search }
  it_behaves_like "cms_node#spec"
end

describe Facility::Node::Category, type: :model, dbscope: :example do
  let(:item) { create :facility_node_category }
  it_behaves_like "cms_node#spec"
end

describe Facility::Node::Service, type: :model, dbscope: :example do
  let(:item) { create :facility_node_service }
  it_behaves_like "cms_node#spec"
end

describe Facility::Node::Location, type: :model, dbscope: :example do
  let(:item) { create :facility_node_location }
  it_behaves_like "cms_node#spec"
end
