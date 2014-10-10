class SS::Sequence
  include Mongoid::Document

  field :id, type: String
  field :value, type: Integer

  class << self
    def next_sequence(coll, name)
      sid = "#{coll}_#{name}"
      doc = where(_id: sid).find_and_modify({"$inc" => { value: 1 }}, new: true)
      return doc.value if doc

      key = (name == :id) ? :_id : name
      doc = collection.database[coll].find.sort(key => -1).first
      val = doc ? doc[key].to_i + 1 : 1
      self.new(_id: sid, value: val).save ? val : nil
    end

    def unset_sequence(coll, name)
      sid = "#{coll}_#{name}"
      SS::Sequence.destroy_all(_id: sid)
    end
  end
end
