require 'spec_helper'

describe History::Log do
  subject(:model) { History::Log }
  subject(:factory) { :history_log }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
