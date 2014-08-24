# coding: utf-8
module Faq::Addons::Question
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell
  end

  class ViewCell < Cell::Rails
    include SS::AddonFilter::ViewCell
  end
end
