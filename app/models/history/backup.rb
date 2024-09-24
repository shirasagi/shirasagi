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
    
    true
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

      column_value_ids = []
      current.data["column_values"].each do |column_value|
        column_value_ids << column_value["_id"]
      end
    
      if column_value_ids 
        column_value_ids.each do |id|
          item.column_values.find_by(id: id)&.destroy
        end
      end

      if current
        # don't touch "updated"
        current.without_record_timestamps { current.save }
      end
      if before
        # don't touch "updated"
        before.without_record_timestamps { before.save }
      end

      return true
    rescue => e
      errors.add :base, "error. #{e}"
      return false
    end
  end
end
