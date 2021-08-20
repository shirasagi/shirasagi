class History::Log
  include SS::Document
  include SS::Reference::User
  include History::Searchable
  # include SS::Reference::Site

  store_in_repl_master
  index(created: 1)

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
      log.ref_coll     = options[:item].try(:collection_name) if options[:item]
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

    def enum_csv(options)
      exporter = SS::Csv.draw(:export, context: self) do |drawer|
        drawer.column :created
        drawer.column :user_name do
          drawer.body { |item| item.user_label }
        end
        drawer.column :model_name do
          drawer.body { |item| item.target_label }
        end
        drawer.column :action
        drawer.column :path do
          drawer.body { |item| item.url }
        end
        drawer.column :session_id
        drawer.column :request_id
      end

      exporter.enum(all, options)
    end
  end
end
