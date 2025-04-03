class SS::TempFileFrameSetting
  include ActiveModel::Model

  attr_accessor :field_name, :accepts
  attr_writer :show_properties, :show_attach, :show_delete, :show_copy_url, :show_opendata

  private_class_method :new

  class << self
    def decode(setting)
      return self.default if setting.blank? || setting == "-"
      setting = JSON::JWS.decode_compact_serialized(setting, Rails.application.secret_key_base)
      new(setting)
    end

    def default
      @default ||= new
    end
  end

  def show_properties
    return @show_properties if instance_variable_defined?(:@show_properties)
    true
  end

  def show_attach
    return @show_attach if instance_variable_defined?(:@show_attach)
    true
  end

  def show_delete
    return @show_delete if instance_variable_defined?(:@show_delete)
    true
  end

  def show_copy_url
    return @show_copy_url if instance_variable_defined?(:@show_copy_url)
    false
  end

  def show_opendata
    return @show_opendata if instance_variable_defined?(:@show_opendata)
    true
  end
end
