# coding: utf-8
module Cms::Parts::Tabs
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Tabs
  end
end
