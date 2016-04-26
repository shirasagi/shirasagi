module SS::TemplateVariable
  extend ActiveSupport::Concern

  module ClassMethods
    def template_variable_handlers
      instance_variable_get(:@_template_variable_handlers) || []
    end

    def template_variable_handlers=(value)
      instance_variable_set(:@_template_variable_handlers, value)
    end

    def template_variable_handler(name, proc = nil, &block)
      handlers = template_variable_handlers

      name = name.to_sym if name.respond_to?(:to_sym)
      handlers << [name, proc || block]
      self.template_variable_handlers = handlers
    end

    def render_template(*args)
      options = args.extract_options!
      new(options).render_template(*args)
    end
  end

  def render_template(template, *args)
    return '' if template.blank?
    template.gsub(/\#\{(.*?)\}/) do |m|
      str = template_variable_get($1, *args) rescue false
      str == false ? m : str
    end
  end

  private
    def template_variable_get(name, *args)
      handler = find_template_variable_handler(name)
      return unless handler

      handler.call(name, *args)
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      false
    end

    def find_template_variable_handler(name)
      name = name.to_sym
      handler_def = self.class.template_variable_handlers.find { |handler_name, _| handler_name == name }
      return nil unless handler_def

      case handler = handler_def[1]
      when ::Symbol, ::String
        method(handler)
      when ::Proc
        myself = self
        lambda { |name, value| myself.instance_exec(name, value, &handler) }
      else
        # we expect a object responding to :call
        handler
      end
    end
end
