class Opendata::Api::ParamBase
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :cur_site
  alias site cur_site

  validate :validate_param

  def res
    valid? ? res_valid : res_invalid
  end

  def help
  end

  private

  def res_valid
    { help: help, success: true }
  end

  def res_invalid
    error = {__type: "Validation Error"}
    self.errors.each { |k, v| error[k] = v }

    { help: help, success: false, error: error }
  end

  def check_num(key)
    num = send(key)
    if num.blank?
      self.send("#{key}=", nil)
      return
    end
    if num.numeric? && num.to_i >= 0
      self.send("#{key}=", num.to_i)
      return
    end
    self.errors.add key, "Must be a natural number"
  end

  def validate_param
  end
end
