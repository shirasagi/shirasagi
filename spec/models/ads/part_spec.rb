require 'spec_helper'

describe Ads::Part::Banner do
  subject(:model) { Ads::Part::Banner }
  subject(:factory) { :ads_part_banner }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
