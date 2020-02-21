class SS::Migration20161226000000
  include SS::Migration::Base

  depends_on "20160225000000"

  def change
    SS::Site.remove_indexes
    SS::Site.each(&:save!)
    SS::Site.create_indexes
  end
end
