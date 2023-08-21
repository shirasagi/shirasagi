class SS::Migration20210212000000
  include SS::Migration::Base

  depends_on "20201204000000"

  def change
    inquiry_permissions = %w(
      read_other_inquiry_columns
      read_private_inquiry_columns
      edit_other_inquiry_columns
      edit_private_inquiry_columns
      delete_other_inquiry_columns
      delete_private_inquiry_columns
      read_other_inquiry_answers
      read_private_inquiry_answers
      edit_other_inquiry_answers
      edit_private_inquiry_answers
      delete_other_inquiry_answers
      delete_private_inquiry_answers
    )
    ::Cms::Role.each do |role|
      next if role.created > Time.zone.parse("2021/02/12")
      role.add_to_set(permissions: inquiry_permissions)
    end
  end
end
