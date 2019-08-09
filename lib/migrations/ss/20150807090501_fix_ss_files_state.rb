class SS::Migration20150807090501
  include SS::Migration::Base

  depends_on "20150619114301"

  def change
    Cms::Page.all.each do |item|
      item.files.each do |f|
        if item.state == "closed" && f.state == "public"
          f.update_attributes(state: item.state)
        end
      end
    end

    Facility::Image.all.each do |item|
      f = item.image
      next unless f

      if item.state == "closed" && f.state == "public"
        f.update_attributes(state: item.state)
      end
    end
  end
end
