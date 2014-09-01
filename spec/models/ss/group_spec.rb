require 'spec_helper'

describe SS::Group do
  subject(:model) { SS::Group }
  subject(:factory) { :ss_group }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
