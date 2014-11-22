require 'spec_helper'

describe Opendata::Node::Category do
  subject(:model) { Opendata::Node::Category }
  subject(:factory) { :opendata_node_category }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::Area do
  subject(:model) { Opendata::Node::Area }
  subject(:factory) { :opendata_node_area }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::Dataset do
  subject(:model) { Opendata::Node::Dataset }
  subject(:factory) { :opendata_node_dataset }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::DatasetCategory do
  subject(:model) { Opendata::Node::DatasetCategory }
  subject(:factory) { :opendata_node_dataset_category }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::DatasetGroup do
  subject(:model) { Opendata::Node::SearchDatasetGroup }
  subject(:factory) { :opendata_node_search_dataset_group }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::SearchDataset do
  subject(:model) { Opendata::Node::SearchDataset }
  subject(:factory) { :opendata_node_search_dataset }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::Sparql do
  subject(:model) { Opendata::Node::Sparql }
  subject(:factory) { :opendata_node_sparql }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::Api do
  subject(:model) { Opendata::Node::Api }
  subject(:factory) { :opendata_node_api }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::App do
  subject(:model) { Opendata::Node::App }
  subject(:factory) { :opendata_node_app }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::Idea do
  subject(:model) { Opendata::Node::Idea }
  subject(:factory) { :opendata_node_idea }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::Mypage do
  subject(:model) { Opendata::Node::Mypage }
  subject(:factory) { :opendata_node_mypage }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::MyProfile do
  subject(:model) { Opendata::Node::MyProfile }
  subject(:factory) { :opendata_node_my_profile }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::MyDataset do
  subject(:model) { Opendata::Node::MyDataset }
  subject(:factory) { :opendata_node_my_dataset }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::MyApp do
  subject(:model) { Opendata::Node::MyApp }
  subject(:factory) { :opendata_node_my_app }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Node::MyIdea do
  subject(:model) { Opendata::Node::MyIdea }
  subject(:factory) { :opendata_node_my_idea }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
