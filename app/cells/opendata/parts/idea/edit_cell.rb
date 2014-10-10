module Opendata::Parts::Idea
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Opendata::Part::Idea
  end
end
