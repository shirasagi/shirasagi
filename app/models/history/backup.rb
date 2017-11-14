class History::Backup
  include SS::Document
  include SS::Reference::User

  store_in_repl_master
  index({ ref_coll: 1, "data._id" => 1, created: -1 })

  cattr_reader(:max_age) { 20 }

  field :version, type: String, default: SS.version
  field :ref_coll, type: String
  field :ref_class, type: String
  field :data, type: Hash

  validates :ref_coll, presence: true
  validates :data, presence: true

  def coll
    collection.database[ref_coll]
  end

  def get
    coll.find(_id: data["_id"]).first
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
    data.delete("file_ids") # TODO: for attachment files

    begin
      resp = query.update_many('$set' => data)
      return true
    rescue => e
      errors.add :base, "error. #{e}"
      return false
    end
  end
end
