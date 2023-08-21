module Gws::Break
  def break_options
    %w(vertically horizontal).collect { |v| [ I18n.t("gws.options.break.#{v}"), v ] }
  end
end
