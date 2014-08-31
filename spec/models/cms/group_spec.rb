require 'spec_helper'

describe Cms::Group do
  subject(:model) { Cms::Group }
  subject(:factory) { :ss_group }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
