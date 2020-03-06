module SS::Model::PrefectureCode
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    store_in collection: "ss_pref_codes"

    seqid :id
    field :code, type: String
    field :prefecture, type: String
    field :prefecture_kana, type: String
    field :city, type: String
    field :city_kana, type: String

    permit_params :code, :prefecture, :prefecture_kana, :city, :city_kana

    validates :code, presence: true, uniqueness: true, length: { is: 6 }, numericality: { only_integer: true }
    validate :validate_code_check_digit
    validates :prefecture, presence: true, length: { maximum: 40 }
    validates :prefecture_kana, length: { maximum: 40 }
    validates :city, length: { maximum: 40 }
    validates :city_kana, length: { maximum: 40 }

    index({ code: 1 }, { unique: true })
  end

  def name
    n = []
    n << prefecture
    n << city if city.present?
    n.join(" ")
  end

  module ClassMethods
    def search(params = {})
      all.search_name(params).search_keyword(params).search_code(params)
    end

    def search_name(params = {})
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params = {})
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :code, :prefecture, :prefecture_kana, :city, :city_kana
    end

    def search_code(params = {})
      return all if params.blank?

      code = params[:code]
      return all if code.blank?

      # normalize postal code
      code = code.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z').gsub(/[^0-9a-zA-Z]/, '')
      all.where(code: code)
    end

    def to_csv
      CSV.generate do |data|
        data << %w(code prefecture prefecture_kana city city_kana)
        criteria.each do |item|
          line = []
          line << item.code
          line << item.prefecture
          line << item.prefecture_kana
          line << item.city
          line << item.city_kana
          data << line
        end
      end
    end

    def check_digit(code)
      sum = code[0].to_i * 6 + code[1].to_i * 5 + code[2].to_i * 4 + code[3].to_i * 3 + code[4].to_i * 2
      mod = sum % 11
      (11 - mod).to_s.last
    end
  end

  private

  def validate_code_check_digit
    return if code.blank? || code.length != 6 || !code.numeric?

    check = self.class.check_digit(code)
    return if code[5] == check

    errors.add :code, :invalid_code
  end
end
