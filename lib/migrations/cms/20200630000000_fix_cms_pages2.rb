class SS::Migration20200630000000
  include SS::Migration::Base

  depends_on "20200526000000"

  def change
    Cms::Page.create_indexes
  end
end
