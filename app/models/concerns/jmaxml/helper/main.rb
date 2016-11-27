module Jmaxml::Helper::Main
  extend ActiveSupport::Concern
  include Jmaxml::Helper::ControlHandler
  include Jmaxml::Helper::HeadHandler
  include Jmaxml::Helper::EarthquakeHandler
  include Jmaxml::Helper::VolcanoHandler
  include Jmaxml::Helper::CommentHandler
  include Jmaxml::Helper::OfficeInfoHandler

  def xmldoc
    @xmldoc
  end

  def render_title
    head_title
  end

  def publishing_offices
    names = office_info_names
    return names if names.present?
    [ control_publishing_office ]
  end

  def to_zenkaku(str)
    str.to_s.tr('0-9a-zA-Z', '０-９ａ-ｚＡ-Ｚ')
  end
end
