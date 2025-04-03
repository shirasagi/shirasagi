class SS::TempFileFrameSetting
  include ActiveModel::Model

  attr_accessor :field_name, :show_properties, :show_attach, :show_delete, :show_copy_url, :show_opendata, :accepts

  private_class_method :new

  class << self
    def decode(config)
      return self.default if config.blank? || config == "-"
      new(JSON::JWS.decode_compact_serialized(config, Rails.application.secret_key_base))
    end

    def default
      @default ||= new
    end
  end

  def to_jws
    JSON::JWT.new({ field_name: field_name, accepts: accepts }).sign(Rails.application.secret_key_base).to_s
  end

  def encode
    return "-" if file_view.blank? || accepts.blank?

    to_jws
  end
end
