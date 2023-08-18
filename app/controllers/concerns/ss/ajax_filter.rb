module SS::AjaxFilter
  extend ActiveSupport::Concern

  included do
    layout "ss/ajax"
  end
end
