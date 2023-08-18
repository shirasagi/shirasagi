require 'spec_helper'

describe Ads::Part::Banner, type: :model, dbscope: :example do
  let(:item) { create :ads_part_banner }
  it_behaves_like "cms_part#spec"
end
