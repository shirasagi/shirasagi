require 'spec_helper'

describe Faq::Part::Search do
  subject(:model) { Faq::Part::Search }
  subject(:factory) { :faq_part_search }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
