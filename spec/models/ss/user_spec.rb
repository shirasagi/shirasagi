require 'spec_helper'

describe SS::User do
  subject(:model) { SS::User }
  subject(:factory) { :ss_user }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
