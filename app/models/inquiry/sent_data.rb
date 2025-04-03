class Inquiry::SentData
  include SS::Document

  field :data, type: Hash, default: {}
  field :token, type: String

  before_validation :set_token
  validates :data, :token, presence: true

  def set_token
    self.token ||= SecureRandom.uuid
  end

  class << self
    def apply(answer_data)
      data = {}
      answer_data.each do |column_id, values|
        value = values[0]
        if value.is_a?(String)
          data[column_id] = value
        elsif value.is_a?(Hash)
          data[column_id] = value.values.join("\n")
        elsif value.respond_to?(:original_filename)
          data[column_id] = value.original_filename
        elsif value.respond_to?(:filename)
          data[column_id] = value.filename
        end
      end
      return if data.blank?

      item = self.new
      item.data = data
      item.save!
      item
    end

    def find_by_token(token)
      # 作成時より1日のみ有効
      self.and([
        { token: token },
        { created: { "$gt" => Time.zone.now.advance(days: -1) } }
      ]).first
    end
  end
end
