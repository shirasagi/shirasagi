require 'spec_helper'

describe Sys::User do
  subject(:model) { Sys::User }
  subject(:factory) { :ss_user }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
