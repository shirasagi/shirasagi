require 'spec_helper'

describe Event::Node::Base do
  subject(:model) { Event::Node::Base }
  subject(:factory) { :event_node_base }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end

describe Event::Node::Page do
  subject(:model) { Event::Node::Page }
  subject(:factory) { :event_node_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
