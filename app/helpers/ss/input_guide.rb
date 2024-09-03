module SS::InputGuide
  extend ActiveSupport::Concern

  def ss_input_guide(attribute, model: nil, **options)
    model ||= @model
    options = { count: 1 }.merge!(options)
    parts = attribute.to_s.split(".")
    attribute = parts.pop
    namespace = parts.join("/") unless parts.empty?
    attributes_scope = "input_guide"

    if namespace
      defaults = Enumerator.new do |y|
        model.lookup_ancestors.flat_map do |klass|
          y << :"#{attributes_scope}.#{klass.model_name.i18n_key}/#{namespace}.#{attribute}_html"
          y << "#{attributes_scope}.#{klass.model_name.i18n_key}/#{namespace}.#{attribute}"
        end
        y << :"#{attributes_scope}.#{namespace}.#{attribute}"
      end
    else
      defaults = Enumerator.new do |y|
        model.lookup_ancestors.flat_map do |klass|
          y << :"#{attributes_scope}.#{klass.model_name.i18n_key}.#{attribute}_html"
          y << :"#{attributes_scope}.#{klass.model_name.i18n_key}.#{attribute}"
        end
      end
    end

    default_option = options.delete(:default) if options[:default]
    translation = nil
    defaults.each do |key|
      translation = I18n.t(key, default: nil, **options)
      next if translation.nil?

      translation = translation.html_safe if key.to_s.end_with?("_html")
      break
    end

    translation ||= default_option
    translation ||= attribute.humanize
    tag.div(translation, class: "ss-input-guide")
  end
end
