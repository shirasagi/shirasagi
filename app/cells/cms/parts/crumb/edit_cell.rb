# coding: utf-8
module Cms::Parts::Crumb
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Crumb
  end
end
