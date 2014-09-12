# coding: utf-8
module Cms::Addons::Body
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell

    javascript "cms/form"
  end
end
