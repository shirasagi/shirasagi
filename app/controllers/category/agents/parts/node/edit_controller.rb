module Category::Agents::Parts::Node
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Category::Part::Node
  end
end
