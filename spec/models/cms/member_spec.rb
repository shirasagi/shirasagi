require 'spec_helper'

describe Cms::Member do
  subject(:model) { Cms::Member }
  subject(:factory) { :cms_member }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }
  end
end
