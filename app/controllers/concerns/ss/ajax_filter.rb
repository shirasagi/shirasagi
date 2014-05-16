# coding: utf-8
module SS::AjaxFilter
  extend ActiveSupport::Concern
  
  included do
    layout "ss/ajax"
  end
end
