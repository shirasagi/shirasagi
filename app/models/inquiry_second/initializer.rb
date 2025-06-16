module InquirySecond
  class Initializer
    Cms::Node.plugin "inquiry_second/form"
    Cms::Node.plugin "inquiry_second/node"

    Cms::Part.plugin "inquiry_second/feedback"

    Cms::Role.permission :read_other_inquiry_second_columns
    Cms::Role.permission :read_private_inquiry_second_columns
    Cms::Role.permission :edit_other_inquiry_second_columns
    Cms::Role.permission :edit_private_inquiry_second_columns
    Cms::Role.permission :delete_other_inquiry_second_columns
    Cms::Role.permission :delete_private_inquiry_second_columns

    Cms::Role.permission :read_other_inquiry_second_answers
    Cms::Role.permission :read_private_inquiry_second_answers
    Cms::Role.permission :edit_other_inquiry_second_answers
    Cms::Role.permission :edit_private_inquiry_second_answers
    Cms::Role.permission :delete_other_inquiry_second_answers
    Cms::Role.permission :delete_private_inquiry_second_answers
  end
end
