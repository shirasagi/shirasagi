module Opendata::Parts::Dataset
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Opendata::Part::Dataset
  end
end
