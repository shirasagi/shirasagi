class Translate::AccessLog
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_tools", :use

  store_in_repl_master
  index({ created: -1 })

  field :path, type: String
  field :remote_addr, type: String
  field :user_agent, type: String
  field :referer, type: String
  field :deny_message, type: String

  validates :path, presence: true

  default_scope ->{ order_by(created: -1) }

  def bot?
    return false if user_agent.blank?
    Browser.new(user_agent).bot?
  end

  class << self
    def create_log!(site, request, deny_message)
      item = self.new
      item.cur_site = site
      item.path = request.path
      item.user_agent = request.user_agent
      item.remote_addr = request.remote_addr
      item.referer = request.referer
      item.deny_message = deny_message
      item.save!
      item
    end

    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :path
      end
      criteria
    end

    def enum_csv(options)
      exporter = SS::Csv.draw(:export, context: self) do |drawer|
        drawer.column :created
        drawer.column :path
        drawer.column :user_agent
        drawer.column :remote_addr
        drawer.column :referer
        drawer.column :deny_message
      end

      exporter.enum(all, options)
    end
  end
end
