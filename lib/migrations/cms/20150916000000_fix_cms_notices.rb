class SS::Migration20150916000000
  def change
    Cms::Notice.where(released: nil).each do |item|
      item.state  ||= "public"
      item.released = item.release_date || item.updated
      item.save
    end
  end
end
