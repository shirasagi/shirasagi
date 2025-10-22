module Inquiry
  class Initializer
    Cms::Node.plugin "inquiry/form"
    Cms::Node.plugin "inquiry/node"

    Cms::Part.plugin "inquiry/feedback"

    Cms::Role.permission :read_other_inquiry_columns
    Cms::Role.permission :read_private_inquiry_columns
    Cms::Role.permission :edit_other_inquiry_columns
    Cms::Role.permission :edit_private_inquiry_columns
    Cms::Role.permission :delete_other_inquiry_columns
    Cms::Role.permission :delete_private_inquiry_columns

    Cms::Role.permission :read_other_inquiry_answers
    Cms::Role.permission :read_private_inquiry_answers
    Cms::Role.permission :edit_other_inquiry_answers
    Cms::Role.permission :edit_private_inquiry_answers
    Cms::Role.permission :delete_other_inquiry_answers
    Cms::Role.permission :delete_private_inquiry_answers

    Inquiry::Column.plugin 'inquiry/text_field'
    Inquiry::Column.plugin 'inquiry/text_area'
    Inquiry::Column.plugin 'inquiry/email_field'
    Inquiry::Column.plugin 'inquiry/number_field'
    Inquiry::Column.plugin 'inquiry/date_field'
    Inquiry::Column.plugin 'inquiry/datetime_field'
    Inquiry::Column.plugin 'inquiry/radio_button'
    Inquiry::Column.plugin 'inquiry/select'
    Inquiry::Column.plugin 'inquiry/check_box'
    Inquiry::Column.plugin 'inquiry/upload_file'
    Inquiry::Column.plugin 'inquiry/form_select'
    Inquiry::Column.plugin 'inquiry/section'
  end
end
