require 'spec_helper'

describe Cms::User do
  subject(:model) { Cms::User }
  subject(:factory) { :ss_user }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
