module Category::Parts::Node
  class EditController < ApplicationController
    include Cms::PartFilter::EditCell
    model Category::Part::Node
  end
end
