module Opendata::Addon::PrefCode
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    belongs_to :pref_code, class_name: 'SS::PrefectureCode'
    permit_params :pref_code_id
  end

  def pref_code_options
    SS::PrefectureCode.all.map do |item|
      ["#{item.name} (#{item.code})", item.id]
    end
  end
end

