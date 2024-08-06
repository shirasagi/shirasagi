class Gws::Column::RestoreService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :filename

  def zip
    @zip ||= ::Zip::File.open(filename)
  end

  def close
    @zip.close if @zip
    @zip = nil
  end

  def model
    return @model if instance_variable_defined?(:@model)

    entry = zip.find_entry("tail.json")
    if entry.blank?
      @model = nil
      return @model
    end

    tail = entry.get_input_stream { |io| JSON.parse(io.read) }
    model_name = tail["model"]
    if model_name.blank?
      @model = nil
      return @model
    end

    model_class = model_name.constantize
    if tail["collection"] != model_class.collection_name.to_s
      @model = nil
      return @model
    end

    @model = model_class
  end

  def valid?
    model.present?
  end

  def each_form
    zip.glob("db/#{model.collection_name}/*.bson").each do |entry|
      bson = entry.get_input_stream { |io| Hash.from_bson(BSON::ByteBuffer.new(io.read)) }
      yield Mongoid::Factory.from_db(model, bson)
    rescue => e
      Rails.logger.error("#{entry.name}: failed to load")
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    end
  end

  def each_column
    zip.glob("db/#{Gws::Column::Base.collection_name}/*.bson").each do |entry|
      bson = entry.get_input_stream { |io| Hash.from_bson(BSON::ByteBuffer.new(io.read)) }
      yield Mongoid::Factory.from_db(Gws::Column::Base, bson)
    rescue => _e
      Rails.logger.error("#{entry.name}: failed to load")
      raise
    end
  end
end
