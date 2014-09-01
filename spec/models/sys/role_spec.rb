require 'spec_helper'

describe Sys::Role do
  subject(:model) { Sys::Role }
  subject(:factory) { :sys_role }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
