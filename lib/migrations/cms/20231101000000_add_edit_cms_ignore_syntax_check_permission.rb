class SS::Migration20231101000000
  include SS::Migration::Base

  depends_on "20230410000004"

  def change
    ::Cms::Role.all.add_to_set(permissions: 'edit_cms_ignore_syntax_check')
  end
end
