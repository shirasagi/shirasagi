class Gws::Memo::Folder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include SS::Fields::DependantNaming

  set_permission_name 'gws_memo_messages'

  seqid :id
  field :name, type: String
  field :path, type: String
  field :order, type: Integer, default: 0

  has_many :filters, class_name: 'Gws::Memo::Filter'

  permit_params :name, :order, :path

  validates :name, presence: true, uniqueness: { scope: [:site_id, :user_id] }, length: {maximum: 80}
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validate :validate_parent_name

  default_scope ->{ order_by order: 1 }

  scope :children, ->(name) do
    if name == I18n.t('gws/memo/folder.inbox')
      where('$and' => [ {name: /^(?!.*\/).*$/} ] )
    else
      where('$and' => [ {name: /#{name}\/(?!.*\/).*$/} ] )
    end
  end

  scope :descendent, ->(name) { where( name: /^#{Regexp.escape(name)}\// ) }

  before_destroy :validate_destroy

  private

  def validate_parent_name
    return if name.count('/') < 1

    unless self.class.site(site).user(user).where(name: parent_name).exists?
      errors.add :base, :not_found_parent
    end
  end

  def validate_destroy
    errors.add :base, :included_memo if messages.count > 0
    errors.add :base, :used_folder if filters.count > 0
    errors.add :base, :found_children if children.exists?
    errors.empty?
  end

  public

  def parent_name
    File.dirname(name)
  end

  def current_name
    File.basename(name)
  end

  def folder_path
    id == 0 ? path : id.to_s
  end

  def direction
    %w(INBOX.Sent INBOX.Draft).include?(folder_path) ? 'from' : 'to'
  end

  def messages
    Gws::Memo::Message.site(self.site).folder(self, user)
  end

  def unseens
    messages.unseen(self.user_id)
  end

  def unseen?
    unseens.count > 0
  end

  def children
    dependant_scope.children(name)
  end

  def ancestor_or_self
    dependant_scope.where(:name.in => ancestor_or_self_names)
  end

  def ancestor_or_self_names
    name.split('/').each_with_object([]) do |name, ret|
      ret << (ret.last ? "#{ret.last}/#{name}" : name)
    end
  end

  def dependant_scope
    self.class.site(site).user(user)
  end

  def sent_box?
    path == 'INBOX.Sent'
  end

  def draft_box?
    path == 'INBOX.Draft'
  end

  class << self
    #def allow(action, user, opts = {})
    #  super(action, user, opts).where(user_id: user.id)
    #end

    def static_items(user, site)
      [
          self.new(name: I18n.t('gws/memo/folder.inbox'), path: 'INBOX', user_id: user.id, site_id: site.id),
          self.new(name: I18n.t('gws/memo/folder.inbox_trash'), path: 'INBOX.Trash', user_id: user.id, site_id: site.id),
          self.new(name: I18n.t('gws/memo/folder.inbox_draft'), path: 'INBOX.Draft', user_id: user.id, site_id: site.id),
          self.new(name: I18n.t('gws/memo/folder.inbox_sent'), path: 'INBOX.Sent', user_id: user.id, site_id: site.id),
      ]
    end

    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end
end
