# coding: utf-8
module Event::Addons::Date
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell
    
    javascript "event/form"
  end

  class ViewCell < Cell::Rails
    include SS::AddonFilter::ViewCell
  end
end
