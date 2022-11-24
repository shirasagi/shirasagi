module Gws::Memo::MessageHelper
  def searched_label(params)
    return nil if params.blank?

    single_keys = %w(unseen flagged)
    h = params.map do |key, val|
      if single_keys.include?(key)
        Gws::Memo::Message.t(key)
      else
        val.present? ? "#{Gws::Memo::Message.t(key)}: #{val}" : nil
      end
    end.compact

    h.present? ? h.join(', ') : nil
  end
end