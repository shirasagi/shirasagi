module SS::AjaxFilter
  extend ActiveSupport::Concern

  included do
    layout "ss/ajax"
    helper_method :turbo_frame
  end

  def turbo_frame
    @turbo_frame ||= request.headers['Turbo-Frame']
  end
end
