# coding: utf-8
module Cms::Addons::Role
  class ViewCell < Cell::Rails
    include SS::AddonFilter::ViewCell
  end
end
