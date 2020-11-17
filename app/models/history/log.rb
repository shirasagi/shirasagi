class History::Log
  include SS::Document
  include SS::Reference::User
  include History::Searchable
  # include SS::Reference::Site

  store_in_repl_master
  index({ created: -1 })

  attr_accessor :save_term

  field :session_id, type: String
  field :request_id, type: String
  field :url, type: String
  field :controller, type: String
  field :action, type: String
  field :target_id, type: String
  field :target_class, type: String
  field :page_url, type: String
  field :behavior, type: String
  field :ref_coll, type: String
  field :filename, type: String

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
    label
  end

  class << self
    def create_controller_log!(request, response, options)
      return if request.get?
      return if response.code !~ /^3/
      create_log!(request, response, options)
    end

    def create_log!(request, response, options)
      log              = new
      log.session_id   = request.session.id
      log.request_id   = request.uuid
      log.url          = request.path
      log.controller   = options[:controller]
      log.action       = options[:action]
      log.cur_user     = options[:cur_user]
      log.user_id      = options[:cur_user].id if options[:cur_user]
      log.site_id      = options[:cur_site].id if options[:cur_site]
      log.ref_coll     = options[:item].collection_name if options[:item]
      log.filename     = options[:item].data[:filename] if options[:item].try(:ref_coll) == "ss_files"

      if options[:action] == "undo_delete"
        log.behavior = "restore"
      elsif options[:action] == "destroy"
        log.behavior = "delete"
      end

      options[:item].tap do |item|
        if item && item.try(:new_record?)
          log.target_id    = item.id
          log.target_class = item.class
        end
      end

      log.save!
    end

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
