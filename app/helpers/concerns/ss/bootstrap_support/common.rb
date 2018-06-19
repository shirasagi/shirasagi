module SS::BootstrapSupport::Common
  extend ActiveSupport::Concern

  private

  def bt_sup_merge_css_class(scalar_or_array, array)
    ret = bt_sup_normalize_css_class(scalar_or_array)
    ret += array
    ret.uniq!
    ret
  end

  def bt_sup_normalize_css_class(scalar_or_array)
    if scalar_or_array.is_a?(String)
      ret = scalar_or_array.split(/\s+/)
    else
      ret = Array(scalar_or_array).flatten.map(&:to_s)
    end

    ret.reject!(&:blank?)
    ret.uniq!
    ret
  end

  def bt_sup_include_btn_only?(array)
    array.include?('btn') && !array.find { |s| s.start_with?('btn-') }
  end
end
