class Gws::Tabular::FormMigration::BaseConverter
  include ActiveModel::Model

  attr_accessor :field_name, :default_value

  def before_collection(collection)
    # インデックスが変換時の邪魔になるかもしれないので、変換する前に削除する
    collection.indexes.drop_one({ field_name => 1 }) rescue nil
  end

  def after_collection(collection)
  end

  def before_document(doc)
  end

  def after_document(doc)
  end

  def call(value)
    value
  end
end
