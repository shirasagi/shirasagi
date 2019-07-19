class SS::Migration20190619000000
  def change
    ids = Inquiry::Answer.all.pluck(:id)
    ids.each do |id|
      item = Inquiry::Answer.find(id) rescue nil
      next unless item
      item.set(state: item.state)
    end
  end
end
