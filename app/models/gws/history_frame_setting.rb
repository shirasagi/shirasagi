class Gws::HistoryFrameSetting
  include ActiveModel::Model

  attr_accessor :user_id, :model_class, :model_id

  class << self
    def decode(setting)
      return new if setting.blank?
      setting = JSON::JWS.decode_compact_serialized(setting, SS::Crypto.salt)
      new(setting)
    end
  end

  def to_signed_jwt
    JSON::JWT.new(user_id: user_id, model_class: model_class, model_id: model_id).sign(SS::Crypto.salt).to_s
  end
end
