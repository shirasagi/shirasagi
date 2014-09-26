# coding: utf-8
module Opendata::Parts::DatasetGroup
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Opendata::Part::DatasetGroup
  end
end
