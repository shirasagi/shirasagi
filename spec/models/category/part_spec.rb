require 'spec_helper'

describe Category::Part::Base do
  subject(:model) { Category::Part::Base }
  subject(:factory) { :category_part_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Category::Part::Node do
  subject(:model) { Category::Part::Node }
  subject(:factory) { :category_part_node }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
