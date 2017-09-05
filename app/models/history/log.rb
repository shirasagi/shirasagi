class History::Log
  include SS::Document
  include SS::Reference::User
  # include SS::Reference::Site

  index({ created: -1 })

  attr_accessor :save_term

  field :url, type: String
  field :controller, type: String
  field :action, type: String
  field :target_id, type: String
  field :target_class, type: String

  belongs_to :site, class_name: "SS::Site"

  validates :url, presence: true
  validates :controller, presence: true
  validates :action, presence: true

  scope :site, ->(site) { where(site_id: site.id) }

  def save_term_options
    [
      [I18n.t(:"history.save_term.day"), "day"],
      [I18n.t(:"history.save_term.month"), "month"],
      [I18n.t(:"history.save_term.year"), "year"],
      [I18n.t(:"history.save_term.all_save"), "all_save"],
    ]
  end

  def delete_term_options
    [
      [I18n.t(:"history.save_term.year"), "year"],
      [I18n.t(:"history.save_term.month"), "month"],
      [I18n.t(:"history.save_term.all_delete"), "all_delete"],
    ]
  end

  def user_label
    user ? "#{user.name}(#{user_id})" : user_id
  end

  def target_label
    if target_class.present?
      model  = target_class.to_s.underscore
      label  = I18n.t :"mongoid.models.#{model}", default: model
      label += "(#{target_id})" if target_id.present?
    else
      model = controller.singularize
      label = I18n.t :"mongoid.models.#{model}", default: model
    end
  end

  class << self
    def term_to_date(name)
      case name.to_s
      when "year"
        Time.zone.now - 1.year
      when "month"
        # n = Time.zone.now
        # Time.local n.year, n.month, 1, 0, 0, 0
        Time.zone.now - 1.month
      when "day"
        # Time.zone.today.to_time
        Time.zone.now - 1.day
      when "all_delete"
        Time.zone.now
      when "all_save"
        nil
      else
        false
      end
    end
  end
end
