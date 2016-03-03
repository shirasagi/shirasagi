require 'spec_helper'

describe Faq::Part::Search, type: :model, dbscope: :example do
  let(:item) { create :faq_part_search }
  it_behaves_like "cms_part#spec"
end
