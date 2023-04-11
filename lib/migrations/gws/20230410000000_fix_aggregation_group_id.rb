class SS::Migration20230410000000
  include SS::Migration::Base

  # _id を ObjectId から seqid に変更する
  def change
    model = Gws::Aggregation::Group
    return if model.unscoped.count == 0

    sid = "#{model.collection_name}_id"
    sequence = SS::Sequence.find_by(_id: sid) rescue nil
    return if sequence

    attr_array = []
    model.unscoped.each do |item|
      attr = item.attributes
      attr.delete("_id")
      attr_array << attr
    end
    model.collection.drop
    attr_array.each do |attr|
      item = model.new
      item.assign_attributes_safe(attr)
      def item.set_updated; end
      item.save
    end
  end
end
