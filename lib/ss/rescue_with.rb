module SS::RescueWith
  extend ActiveSupport::Concern

  def rescue_with(exception_classes: [StandardError], ensure_p: nil, rescue_p: nil)
    yield
  rescue *exception_classes => e
    if rescue_p
      rescue_p.call(e)
    else
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    end
    nil
  ensure
    ensure_p.call if ensure_p
  end

  def exception_backtrace(exception)
    backtrace_cleaner = ::Rails.backtrace_cleaner
    wrapper = ::ActionDispatch::ExceptionWrapper.new(backtrace_cleaner, exception)

    trace = wrapper.application_trace
    trace = wrapper.framework_trace if trace.empty?

    separator = "\n"

    messages = []
    messages << "#{exception.class} (#{exception.message}):"
    if exception.respond_to?(:annoted_source_code) && exception.annoted_source_code.present?
      messages << exception.annoted_source_code.join(separator)
    end
    messages << trace.map { |message| "  #{message}" }.join(separator)
    messages << "  "

    if block_given?
      messages.each do |message|
        yield message
      end
    end
    messages
  end
end
