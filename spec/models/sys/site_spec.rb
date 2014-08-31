require 'spec_helper'

describe Sys::Site do
  subject(:model) { Sys::Site }
  subject(:factory) { :ss_site }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
