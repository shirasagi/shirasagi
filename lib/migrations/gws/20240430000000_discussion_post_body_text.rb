class SS::Migration20240430000000
  include SS::Migration::Base

  depends_on "20240408000000"

  def change
    ids = Gws::Discussion::Post.exists(form_id: false).pluck(:id)
    ids.each do |id|
      item = Gws::Discussion::Post.find(id) rescue nil
      next if item.nil?
      next if item.body_text.present?

      item.send(:set_body_text)
      item.set(body_text: item.body_text)
    end
  end
end
