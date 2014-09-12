# coding: utf-8
module Category::Parts::Node
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Category::Part::Node
  end
end
