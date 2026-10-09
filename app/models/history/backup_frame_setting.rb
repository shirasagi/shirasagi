class History::BackupFrameSetting
  include ActiveModel::Model

  attr_accessor :ref_path, :ref_class, :ref_id

  class << self
    def decode(setting)
      return new if setting.blank? || setting == "-"
      setting = JSON::JWS.decode_compact_serialized(setting, SS::Crypto.salt)
      new(setting)
    end
  end

  def to_signed_jwt
    JSON::JWT.new(ref_path: ref_path, ref_class: ref_class, ref_id: ref_id).sign(SS::Crypto.salt).to_s
  end
end
