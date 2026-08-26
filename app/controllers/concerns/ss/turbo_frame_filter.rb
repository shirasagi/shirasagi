module SS::TurboFrameFilter
  extend ActiveSupport::Concern

  included do
    helper_method :turbo_frame
  end

  private

  def turbo_frame
    return @turbo_frame if instance_variable_defined?(:@turbo_frame)

    if request.headers.key?('Turbo-Frame')
      @turbo_frame = request.headers['Turbo-Frame'].to_s
    elsif request.headers.key?('X-SS-DIALOG')
      @turbo_frame = "ss-dialog-frame"
    else
      @turbo_frame = nil
    end
  end
end
