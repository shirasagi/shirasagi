class History::Backup
  include History::Model::Data

  def ref_item
    model.relations.each do |k, relation|
      next if relation.class != Mongoid::Association::Embedded::EmbeddedIn

      @nest_parent = relation.class_name.constantize.where(
        relation.inverse_of => { "$elemMatch" => { '_id' => data["_id"] } }
      ).first
      @_ref_item ||= @nest_parent.send(relation.inverse_of).find(data["_id"]) rescue nil

      break @_ref_item if @_ref_item
    end
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
    if ref_item != @nest_parent && @nest_parent.present?
      query = collection.database[@nest_parent.collection_name].find _id: @nest_parent.id
    else
      query = coll.find _id: data["_id"]
    end
    if query.count != 1
      errors.add :base, "#{query.count} documents were found."
      return false
    end

    data = restore_data(data, opts)
    data.delete("_id")
    data.delete("state")

    begin
      if ref_item != @nest_parent && @nest_parent.present?
        ref_item.set(data)
        item = ref_item
      else
        query.update_many('$set' => data)
        item = ref_class.constantize.find(self.data["_id"])
      end
      current = item.current_backup
      before = item.before_backup

      self.state = 'current'
      current.state = 'before' if current
      before.state = nil if before

      self.update
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
