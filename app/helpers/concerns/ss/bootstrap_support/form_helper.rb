module SS::BootstrapSupport::FormHelper
  extend ActiveSupport::Concern
  include SS::BootstrapSupport::Common

  # see: actionview-4.2.9/lib/action_view/helpers/form_helper.rb

  def form_for(record, options = {}, &block)
    options = options.with_indifferent_access
    html_options = options[:html]
    if html_options
      css_class = bt_sup_normalize_css_class(html_options[:class])
      if css_class && !css_class.include?('no-form-inline')
        if css_class.include?('index-search') || css_class.include?('search')
          html_options[:class] = bt_sup_merge_css_class(css_class, %w(form-inline))
          options[:html] = html_options
        end
      end
    end

    super(record, options, &block)
  end

  # def fields_for(record_name, record_object = nil, options = {}, &block)
  #   super
  # end

  # def label(object_name, method, content_or_options = nil, options = nil, &block)
  #   super
  # end

  def text_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def password_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  # def hidden_field(object_name, method, options = {})
  #   super
  # end

  def file_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control-file))
    options[:class] = css_class
    super
  end

  def text_area(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  # def check_box(object_name, method, options = {}, checked_value = "1", unchecked_value = "0")
  #   super
  # end

  # def radio_button(object_name, method, tag_value, options = {})
  #   super
  # end

  def color_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def search_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def telephone_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def date_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def time_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def datetime_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def datetime_local_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def month_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def week_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def url_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def email_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def number_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end

  def range_field(object_name, method, options = {})
    options = options.with_indifferent_access
    css_class = bt_sup_normalize_css_class(options[:class])
    css_class = bt_sup_merge_css_class(css_class, %w(form-control))
    options[:class] = css_class
    super(object_name, method, options)
  end
end
