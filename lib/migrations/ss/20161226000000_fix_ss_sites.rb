class SS::Migration20161226000000
  include SS::Migration::Base

  depends_on "20160225000000"

  def change
    Cms::Site.remove_indexes
    Cms::Site.each do |site|
      site.without_record_timestamps { site.save! }
    end
    Cms::Site.create_indexes
  end
end
