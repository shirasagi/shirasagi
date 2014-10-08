# coding: utf-8
module Opendata::Addons::DatasetNode
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell
    helper Cms::FormHelper
  end
end
