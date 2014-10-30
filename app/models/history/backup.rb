class History::Backup
  include SS::Document
  include SS::Reference::User

  cattr_reader(:max_age) { 5 }

  index({ ref_coll: 1, "data._id" => 1, created: -1 })

  field :version, type: String, default: SS.version
  field :ref_coll, type: String
  field :ref_class, type: String
  field :data, type: Hash

  validates :ref_coll, presence: true
  validates :data, presence: true

  public
    def coll
      collection.database[ref_coll]
    end

    def get
      coll.where(_id: data["_id"]).first
    end

    def restore
      data  = self.data.dup
      query = coll.find _id: data["_id"]
      if query.count != 1
        errors.add :base, "#{query.count} documents were found."
        return false
      end

      data.delete("_id")
      data.delete("file_id")
      data.delete("file_ids")  # TODO: for attachment files

      resp = query.update('$set' => data)
      return true if resp["err"].blank?

      errors.add :base, "error. #{resp['err']}"
      false
    end
end
