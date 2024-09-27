module SS::ExceptionFilter
  extend ActiveSupport::Concern

  def render_exception!(exception)
    backtrace_cleaner = request.get_header("action_dispatch.backtrace_cleaner")
    wrapper = ::ActionDispatch::ExceptionWrapper.new(backtrace_cleaner, exception)
    log_error(request, wrapper)

    if exception.is_a?(Job::SizeLimitPerUserExceededError)
      render_job_size_limit(exception)
      return
    end

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
      template: "ss/rescues/index", layout: @cur_user ? "ss/base" : "ss/login", status: status_code,
      type: request.xhr? ? "text/plain" : "text/html", formats: request.xhr? ? :text : :html
    )
  rescue => e
    Rails.logger.info("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    raise exception
  end

  def log_error(request, wrapper)
    # logger = request.logger || Rails.logger
    logger = Rails.logger
    exception = wrapper.exception

    trace = wrapper.application_trace
    trace = wrapper.framework_trace if trace.empty?

    separator = "\n"
    if logger.formatter && logger.formatter.respond_to?(:tags_text) && logger.formatter.tags_text.present?
      separator << logger.formatter.tags_text
    end

    Rails.application.deprecators.silence do
      logger.fatal "  "
      logger.fatal "#{exception.class} (#{exception.message}):"
      if exception.respond_to?(:annoted_source_code) && exception.annoted_source_code.present?
        logger.fatal exception.annoted_source_code.join(separator)
      end
      logger.fatal "  "
      logger.fatal trace.join(separator)
    end
  end

  def render_job_size_limit(error)
    referer_uri = ::Addressable::URI.parse(request.referer)
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
