class SS::Sequence
  include Mongoid::Document

  field :id, type: String
  field :value, type: Integer

  class << self
    def current_sequence(coll, name, options)
      sid = "#{coll}_#{name}"
      doc = self.with(options[:with] || {}).where(_id: sid).first
      doc ? doc.value : 0
    end

    def next_sequence(coll, name, options)
      model = self.with(options[:with] || {})

      sid = "#{coll}_#{name}"
      doc = model.where(_id: sid).find_one_and_update({"$inc" => { value: 1 }}, return_document: :after, upsert: false)
      return doc.value if doc

      key = (name == :id) ? :_id : name
      doc = model.mongo_client[coll].find.sort(key => -1).first
      val = doc ? doc[key].to_i + 1 : 1
      model.new(_id: sid, value: val).save ? val : nil
    end

    def unset_sequence(coll, name, options)
      sid = "#{coll}_#{name}"
      self.with(options[:with] || {}).destroy_all(_id: sid)
    end
  end
end
