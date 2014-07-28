# coding: utf-8
module Inquiry::Addons::Captcha
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell
  end

  class ViewCell < Cell::Rails
    include SS::AddonFilter::ViewCell
  end
end
