require 'spec_helper'

describe Category::Part::Base, type: :model, dbscope: :example do
  let(:item) { create :category_part_base }
  it_behaves_like "cms_part#spec"
end

describe Category::Part::Node, type: :model, dbscope: :example do
  let(:item) { create :category_part_node }
  it_behaves_like "cms_part#spec"
end
