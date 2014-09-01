require 'spec_helper'

describe Sys::Group do
  subject(:model) { Sys::Group }
  subject(:factory) { :ss_group }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
