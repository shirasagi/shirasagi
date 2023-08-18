class Gws::Memo::Folder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include SS::Fields::DependantNaming
  include Gws::Model::Memo::Folder

  STATIC_FOLDER_NAMES = %w(INBOX INBOX.Trash INBOX.Draft INBOX.Sent).freeze

  set_permission_name 'private_gws_memo_messages', :edit

  seqid :id
  field :name, type: String
  field :path, type: String
  field :order, type: Integer, default: 0

  has_many :filters, class_name: 'Gws::Memo::Filter'

  permit_params :name, :order, :path, :in_parent, :in_basename

  validates :name, presence: true, uniqueness: { scope: [:site_id, :user_id] }, length: {maximum: 80}
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validate :validate_parent_name

  before_validation :set_name_and_depth, if: ->{ in_basename.present? }
  default_scope ->{ order_by order: 1 }

  scope :children, ->(name) do
    if name == I18n.t('gws/memo/folder.inbox')
      where('$and' => [ {name: /^(?!.*\/).*$/} ] )
    else
      where('$and' => [ {name: /#{name}\/(?!.*\/).*$/} ] )
    end
  end

  scope :descendent, ->(name) { where( name: /^#{::Regexp.escape(name)}\// ) }

  before_destroy :destroy_folders
  before_destroy :validate_destroy

  private

  def validate_parent_name
    return if name.count('/') < 1

    unless self.class.user(user).where(name: parent_name).exists?
      errors.add :base, :not_found_parent
    end
  end

  def validate_destroy
    errors.add :base, :included_memo if messages.count > 0
    errors.add :base, :used_folder if filters.count > 0
    errors.add :base, :found_children if children.exists?
    errors.empty?
  end

  def destroy_children
    dependant_scope.ne(_id: _id).where(name: /^#{::Regexp.escape(name)}\//).find_each(&:destroy)
  end

  def verify_folders
    folders = dependant_scope.where(name: /^#{name}.*/)
    folders.each do |folder|
      next if folder.messages.blank?
      errors.add :base, I18n.t("mongoid.errors.models.gws/memo/folder.found_messages", name: folder.name)
    end
  end

  def destroy_folders
    verify_folders
    return throw :abort if errors.present?
    destroy_children
  end

  public

  def parent_name
    File.dirname(name)
  end

  def current_name
    File.basename(name)
  end

  def folder_path
    new_record? ? path : id.to_s
  end

  def direction
    %w(INBOX.Sent INBOX.Draft).include?(folder_path) ? 'from' : 'to'
  end

  def messages
    if user
      Gws::Memo::Message.folder(self, user)
    else
      Gws::Memo::Message.none
    end
  end

  def unseens
    return messages.none if sent_box? || draft_box?
    messages.site(site).unseen(user, path: folder_path)
  end

  def unseen?
    return false if sent_box? || draft_box?
    unseens.count > 0
  end

  def children
    dependant_scope.children(name)
  end

  def ancestor_or_self
    dependant_scope.reorder(:name.asc).where(:name.in => ancestor_or_self_names)
  end

  def ancestor_or_self_names
    name.split('/').each_with_object([]) do |name, ret|
      ret << (ret.last ? "#{ret.last}/#{name}" : name)
    end
  end

  def dependant_scope
    if site && user
      self.class.site(site).user(user)
    else
      self.class.none
    end
  end

  def sent_box?
    path == 'INBOX.Sent'
  end

  def draft_box?
    path == 'INBOX.Draft'
  end

  class << self
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
