class SS::Migration20150916000000
  include SS::Migration::Base

  depends_on "20150807090501"

  def change
    Cms::Notice.where(released: nil).each do |item|
      item.state  ||= "public"
      item.released = item.release_date || item.updated
      item.without_record_timestamps { item.save }
    end
  end
end
