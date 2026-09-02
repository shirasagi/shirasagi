module SS::AjaxFilter
  extend ActiveSupport::Concern
  include SS::TurboFrameFilter

  included do
    layout "ss/ajax"
  end
end
