# coding: utf-8
module Cms::Addons::Role
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell
  end
end
