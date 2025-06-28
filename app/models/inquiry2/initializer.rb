module Inquiry2
  class Initializer
    Cms::Node.plugin "inquiry2/form"
    Cms::Node.plugin "inquiry2/node"

    # Cms::Part.plugin "inquiry2/feedback"

    Inquiry2::Column.plugin 'cms/text_field'
    Inquiry2::Column.plugin 'cms/date_field'
    Inquiry2::Column.plugin 'cms/url_field2'
    Inquiry2::Column.plugin 'cms/text_area'
    Inquiry2::Column.plugin 'cms/select'
    Inquiry2::Column.plugin 'cms/radio_button'
    Inquiry2::Column.plugin 'cms/check_box'
    # Inquiry2::Column.plugin 'cms/file_upload'
    # Inquiry2::Column.plugin 'cms/form_select'
  end
end
