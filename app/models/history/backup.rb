class History::Backup
  include History::Model::Data

  def ref_item
    @_ref_item ||= model.find(data["_id"])
  end

  def get
    item = ref_item
    if item.current_backup
      item.current_backup.data
    else
      item.backups.first.data
    end
  end

  def restorable?
    return false if get == data

    item = ref_item
    if item.respond_to?(:state)
      item.state != "public"
    else
      true
    end
  end

  def restore(opts = {})
    opts[:create_by_trash] = true
    data  = self.data.dup
    query = coll.find _id: data["_id"]
    if query.count != 1
      errors.add :base, "#{query.count} documents were found."
      return false
    end

    data = restore_data(data, opts)
    data.delete("_id")
    data.delete("state")

    begin
      query.update_many('$set' => data)
      item = ref_class.constantize.find(self.data["_id"])
      current = item.current_backup
      before = item.before_backup

      self.state = 'current'
      current.state = 'before' if current
      before.state = nil if before

      self.update
      current.update if current
      before.update if before

      return true
    rescue => e
      errors.add :base, "error. #{e}"
      return false
    end
  end
end
