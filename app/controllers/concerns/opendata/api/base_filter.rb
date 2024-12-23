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
    if num
      if integer?(num)
        if num.to_i < 0
          messages << "Must be a natural number"
        end
      else
        messages << "Invalid integer"
      end
    end
  end

  def integer?(s)
    i = Integer(s)
    check = true
  rescue
    check = false
  end
end
