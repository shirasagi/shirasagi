require 'spec_helper'

describe Kana::Dictionary do
  subject(:model) { Kana::Dictionary }
  subject(:factory) { :kana_dictionary }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
