class SS::Migration20161226000000
  def change
    SS::Site.remove_indexes
    SS::Site.each(&:save!)
    SS::Site.create_indexes
  end
end
