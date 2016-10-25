require 'spec_helper'

describe Event::Part::Search, type: :model, dbscope: :example do
  let(:item) { create :event_part_search }
  it_behaves_like "cms_part#spec"
end
