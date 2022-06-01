class Cms::Line::Area
  include SS::Document
  #include SS::Reference::Site
  #include SS::Reference::User
  include Cms::SitePermission

  field :x, type: Integer
  field :y, type: Integer
  field :width, type: Integer
  field :height, type: Integer

  field :type, type: String
  field :text, type: String
  field :data, type: String
  field :uri, type: String
  belongs_to :menu, class_name: "Cms::Line::Richmenu::Menu"

  validates :x, presence: true
  validates :y, presence: true
  validates :width, presence: true
  validates :height, presence: true

  validates :type, inclusion: { in: %w(message uri postback richmenuswitch) }
  validates :text, presence: true, length: { maximum: 300 }, if: -> { type == "message" }
  validates :uri, presence: true, length: { maximum: 1000 }, if: -> { type == "uri" }
  validates :data, presence: true, length: { maximum: 300 }, if: -> { type == "postback" }
  validates :menu, presence: true, if: -> { type == "richmenuswitch" }

  def type_options
    %w(message uri postback richmenuswitch).map { |k| [I18n.t("cms.options.line_action_type.#{k}"), k] }
  end

  def use_richmenu_alias?
    type == "richmenuswitch" && menu
  end

  def richmenu_object
    bounds = {
      x: x,
      y: y,
      width: width,
      height: height
    }
    action = { type: type }
    case type
    when "message"
      action[:text] = text
    when "uri"
      action[:uri] = uri
    when "postback"
      action[:data] = data
    when "richmenuswitch"
      if menu
        action[:richMenuAliasId] = menu.richmenu_alias
        action[:data] = menu.richmenu_alias
      end
    end
    {
      bounds: bounds,
      action: action
    }
  end

  def image_map_object
    action = {
      type: type,
      area: {
        x: x,
        y: y,
        width: width,
        height: height
      }
    }
    case type
    when "message"
      action[:text] = text
    when "uri"
      action[:linkUri] = uri
    when "postback"
      action[:data] = data
    end
    action
  end
end
