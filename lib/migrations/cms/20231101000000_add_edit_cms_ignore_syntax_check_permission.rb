class SS::Migration20231101000000
  include SS::Migration::Base

  depends_on "20230410000004"

  def change
    ::Cms::Role.each do |role|
      next if role.created > Time.zone.parse("2023/11/01")

      role.add_to_set(permissions: %w(edit_cms_ignore_syntax_check))
    end
  end
end
