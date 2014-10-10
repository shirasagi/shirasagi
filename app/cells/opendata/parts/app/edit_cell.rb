module Opendata::Parts::App
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Opendata::Part::App
  end
end
