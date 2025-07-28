class History::Log
  include SS::Document
  include SS::Reference::User
  include History::Searchable
  # include SS::Reference::Site

  store_in_repl_master
  index(created: 1)

  field :group_ids, type: Array
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

  def group_label
    Cms::Group.in(id: group_ids).map { |group| group.name }.join(",")
  end

  def target_label
    if target_class.present?
      model  = target_class.to_s.underscore
      label  = I18n.t("mongoid.models.#{model}", default: model)
      label += "(#{target_id})" if target_id.present?
    else
      model = controller.singularize
      label = I18n.t("mongoid.models.#{model}", default: model)
    end
    label
  end

  class << self
    def create_controller_log!(request, response, options)
      create_log!(request, response, options) if create_log?(request, response, options)
    end

    def create_log?(request, response, _options)
      return true if !request.get? && !request.head? && response.code.start_with?("3")
      return true if History::DOWNLOAD_MIME_TYPES.include?(response.media_type)
      return true if response["Content-Disposition"].to_s.include?("attachment")

      false
    end

    def create_log!(request, _response, options)
      item             = options[:item]

      log              = new
      log.session_id   = request.session.id
      log.request_id   = request.uuid
      log.url          = SS.request_path(request)
      log.controller   = options[:controller]
      log.action       = options[:action]
      log.cur_user     = options[:cur_user]
      if options[:cur_user]
        log.group_ids  = options[:cur_user].group_ids
        log.user_id    = options[:cur_user].id
      end
      log.site_id      = options[:cur_site].id if options[:cur_site]
      log.ref_coll     = item.collection_name if item.respond_to?(:collection_name)
      log.filename     = item.data[:filename] if item.try(:ref_coll) == "ss_files"

      case options[:action]
      when "undo_delete"
        log.behavior = "restore"
      when "destroy"
        log.behavior = "delete"
      end

      log.target_class = item.class    if item
      log.target_id    = item.try(:id) if item.respond_to?(:new_record?) && !item.try(:new_record?)

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

    def build_file_log(file, options)
      log = History::Log.new

      log.site_id = options[:site_id] || SS.current_site.try(:id)
      log.user_id = options[:user_id] || SS.current_user.try(:id)

      if file
        log.url = file.url
        log.ref_coll = file.class.collection_name.to_s
        log.target_class = file.class.name
        log.target_id = file.id.to_s
      end

      log.session_id = options[:session_id] || Rails.application.current_session_id
      log.request_id = options[:request_id] || Rails.application.current_request_id
      log.controller = options[:controller] || Rails.application.current_controller
      log.page_url = options[:page_url] || Rails.application.current_path_info

      log
    end
  end
end
