module SS::Helpers
  class FormBuilder < ActionView::Helpers::FormBuilder
    public
      def hidden_field(method, options = {})
        return super if method !~ /\[/

        object_method = "#{@object_name}[" + method.sub("[", "][")
        value = options[:value] || array_value(method)
        options.delete(:value)

        if !value.is_a?(Array) || value.size == 0
          return @template.hidden_field_tag(object_method, value, options)
        end

        tags = value.map do |v|
          options[:id] ||= object_method.gsub(/\W+/, "_") + "#{v}"
          @template.hidden_field_tag(object_method, v, options)
        end
        tags.join.html_safe
      end

      def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
        return super if method !~ /\[/

        object_method = "#{@object_name}[" + method.sub("[", "][")
        if method =~ /\[\]$/
          checked = array_value(method).include?(checked_value)
          options[:id] ||= object_method.gsub(/\W+/, "_") + "#{checked_value}"
        else
          checked = array_value(method).present?
        end

        @template.check_box_tag(object_method, checked_value, checked, options)
      end

    private
      def array_value(method)
        item = @template.instance_variable_get(:"@#{@object_name}")
        code = method.sub(/\[\]$/, "").gsub(/\[(\D.*?)\]/, '["\\1"]')

        if method =~ /\[\]$/
          value = eval("item.#{code}") || []
        else
          value = eval("item.#{code}")
        end
      end
  end
end
