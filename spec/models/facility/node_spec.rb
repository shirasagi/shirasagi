require 'spec_helper'

describe Facility::Node::Base do
  subject(:model) { Facility::Node::Base }
  subject(:factory) { :facility_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Facility::Node::Node do
  subject(:model) { Facility::Node::Node }
  subject(:factory) { :facility_node_node }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Facility::Node::Page do
  subject(:model) { Facility::Node::Page }
  subject(:factory) { :facility_node_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Facility::Node::Search do
  subject(:model) { Facility::Node::Search }
  subject(:factory) { :facility_node_search }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Facility::Node::Category do
  subject(:model) { Facility::Node::Category }
  subject(:factory) { :facility_node_category }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Facility::Node::Feature do
  subject(:model) { Facility::Node::Feature }
  subject(:factory) { :facility_node_feature }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Facility::Node::Location do
  subject(:model) { Facility::Node::Location }
  subject(:factory) { :facility_node_location }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
