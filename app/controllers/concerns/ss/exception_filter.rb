module SS::ExceptionFilter
  extend ActiveSupport::Concern

  def render_exception!(exception)
    Rails.logger.fatal("#{exception.class} (#{exception.message}):\n  #{exception.backtrace.join("\n  ")}")

    if exception.is_a?(Job::SizeLimitPerUserExceededError)
      render_job_size_limit(exception)
      return
    end

    backtrace_cleaner = request.get_header("action_dispatch.backtrace_cleaner")
    wrapper = ::ActionDispatch::ExceptionWrapper.new(backtrace_cleaner, exception)
    if exception.is_a?(RuntimeError) && exception.message.numeric?
      status_code = Integer(exception.message)
    else
      status_code = wrapper.status_code
    end

    @ss_rescue = { status: status_code }
    @wrapper = wrapper if Rails.env.development?

    if @ss_mode == :cms && !@cur_site
      @ss_mode = nil
    elsif @ss_mode == :gws && !@cur_site
      @ss_mode = nil
    end

    render(
      file: "ss/rescues/index", layout: @cur_user ? "ss/base" : "ss/login", status: status_code,
      type: request.xhr? ? "text/plain" : "text/html", formats: request.xhr? ? :text : :html
    )
  rescue => e
    Rails.logger.info("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    raise exception
  end

  def render_job_size_limit(error)
    referer_uri = URI.parse(request.referer)
    begin
      if @item.present?
        @item.errors.add(:base, error.to_s)
        flash[:notice] = error.to_s
        render(Rails.application.routes.recognize_path(referer_uri.path))
      else
        redirect_to(referer_uri.path, notice: error.to_s)
      end
    rescue ActionView::MissingTemplate
      redirect_to(referer_uri.path, notice: error.to_s)
    end
  end
end
