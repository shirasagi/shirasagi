class History::Backup
  include SS::Document
  #include SS::Reference::User

  cattr_reader(:max_age) { 5 }

  index({ ref_coll: 1, "data._id" => 1, created: -1 })

  field :version, type: String, default: SS.version
  field :ref_coll, type: String
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
      resp = coll.find(_id: data["_id"]).update(data)
      resp["err"].blank?
    end
end
