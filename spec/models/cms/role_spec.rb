require 'spec_helper'

describe Cms::Role do
  subject(:model) { Cms::Role }
  subject(:factory) { :cms_role }
  
  it_behaves_like "mongoid#save", presence: %w[name permission_level]
  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
