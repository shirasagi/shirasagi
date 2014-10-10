module Cms::Parts::Page
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Page
  end
end
