class SS::Migration20211021000000
  include SS::Migration::Base

  depends_on "20211011000000"

  def change
    Cms::Page.all.exists(released_type: false).set(released_type: "fixed")
  end
end
