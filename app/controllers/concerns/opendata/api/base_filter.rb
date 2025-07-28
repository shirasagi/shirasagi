module Opendata::Api::BaseFilter
  extend ActiveSupport::Concern
  include Opendata::Api::Converter

  private

  def fix_params
    { cur_site: @cur_site }
  end

  def permit_fields
    @model.permitted_fields
  end

  def get_params
    params.permit(permit_fields).merge(fix_params)
  rescue
    {}
  end

  def check_num(num, messages)
    return if num.nil?

    if !integer?(num)
      messages << "Invalid integer"
      return
    end

    if num.to_i < 0
      messages << "Must be a natural number"
    end
  end

  def integer?(num)
    Integer(num)
    true
  rescue
    false
  end
end
