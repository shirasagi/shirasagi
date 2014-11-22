require 'spec_helper'

describe Opendata::Part::MypageLogin do
  subject(:model) { Opendata::Part::MypageLogin }
  subject(:factory) { :opendata_part_mypage_login }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Part::Dataset do
  subject(:model) { Opendata::Part::Dataset }
  subject(:factory) { :opendata_part_dataset }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Part::DatasetGroup do
  subject(:model) { Opendata::Part::DatasetGroup }
  subject(:factory) { :opendata_part_dataset_group }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Part::App do
  subject(:model) { Opendata::Part::App }
  subject(:factory) { :opendata_part_app }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Opendata::Part::Idea do
  subject(:model) { Opendata::Part::Idea }
  subject(:factory) { :opendata_part_idea }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
