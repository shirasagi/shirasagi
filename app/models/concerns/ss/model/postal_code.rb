module SS::Model::PostalCode
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    store_in collection: "ss_postal_codes"

    seqid :id
    field :code, type: String
    field :prefecture, type: String
    field :prefecture_kana, type: String
    field :prefecture_code, type: String
    field :city, type: String
    field :city_kana, type: String
    field :town, type: String
    field :town_kana, type: String

    permit_params :code, :prefecture, :prefecture_kana, :prefecture_code, :city, :city_kana, :town, :town_kana

    validates :code, presence: true, uniqueness: true
    validates :prefecture, presence: true, length: { maximum: 40 }
    validates :prefecture_kana, length: { maximum: 40 }
    validates :prefecture_code, length: { maximum: 40 }
    validates :city, length: { maximum: 40 }
    validates :city_kana, length: { maximum: 40 }
    validates :town, length: { maximum: 80 }
    validates :town_kana, length: { maximum: 80 }

    index({ code: 1 }, { unique: true })
    index({ prefecture_code: 1, code: 1, _id: 1 })
  end

  module ClassMethods
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :code, :prefecture, :prefecture_kana, :prefecture_code,
          :city, :city_kana, :town, :town_kana
      end
      criteria
    end

    def to_csv
      CSV.generate do |data|
        data << %w(code prefecture prefecture_kana prefecture_code city city_kana town town_kana)
        criteria.each do |item|
          line = []
          line << item.code
          line << item.prefecture
          line << item.prefecture_kana
          line << item.prefecture_code
          line << item.city
          line << item.city_kana
          line << item.town
          line << item.town_kana
          data << line
        end
      end
    end
  end
end
