module SS::MaterialIconsHelper
  class MdIcons
    include ActiveModel::Model

    attr_accessor :view_context

    def outlined(name, tag: :span, size: nil, **options)
      icon("material-icons-outlined", name, tag: tag, size: size, **options)
    end

    def filled(name, tag: :span, size: nil, **options)
      icon("material-icons", name, tag: tag, size: size, **options)
    end

    def rounded(name, tag: :span, size: nil, **options)
      icon("material-icons-round", name, tag: tag, size: size, **options)
    end

    def sharp(name, tag: :span, size: nil, **options)
      icon("material-icons-sharp", name, tag: tag, size: size, **options)
    end

    def two_tone(name, tag: :span, size: nil, **options)
      icon("material-icons-two-tone", name, tag: tag, size: size, **options)
    end

    private

    def icon(type, name, tag: :span, size: nil, **options)
      css_classes = Array(options.delete(:class))
      css_classes << type if css_classes.none? { |css_class| css_class =~ /material-icons-\w+/ }
      css_classes << "md-#{size}" if size && css_classes.none? { |css_class| css_class =~ /md-\d+/ }

      if options.key?(:aria)
        options[:aria][:hidden] = true unless options[:aria].key?(:hidden)
      else
        options[:aria] = { hidden: true }
      end
      options[:role] = "img" unless options.key?(:role)

      view_context.tag.send(tag, name, class: css_classes, **options)
    end
  end

  def md_icons
    @md_icons ||= MdIcons.new(view_context: self)
  end
end
