# coding: utf-8
module Cms::Parts::Free
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Free
  end
end
