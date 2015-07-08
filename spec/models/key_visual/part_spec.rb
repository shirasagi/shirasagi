require 'spec_helper'

describe KeyVisual::Part::Slide do
  subject(:model) { KeyVisual::Part::Slide }
  subject(:factory) { :key_visual_part_slide }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
