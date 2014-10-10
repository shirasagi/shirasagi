module Faq::Parts::Search
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Faq::Part::Search
  end
end
