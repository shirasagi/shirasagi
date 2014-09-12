# coding: utf-8
module Cms::Parts::Node
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Node
  end
end
