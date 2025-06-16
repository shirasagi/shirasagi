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
  end
end
