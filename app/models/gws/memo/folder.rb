class Gws::Memo::Folder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_memo_messages'

  seqid :id
  field :name, type: String
  field :path, type: String
  field :order, type: Integer, default: 0

  has_many :filters, class_name: 'Gws::Memo::Filter'

  permit_params :name, :order, :path

  validates :name, presence: true, uniqueness: { scope: :site_id }

  default_scope ->{ order_by order: 1 }

  before_destroy :validate_destroy

  def validate_destroy
    errors.add :base, I18n.t('gws/memo/folder.errors.included_memo') if messages.count > 0
    errors.add :base, I18n.t('gws/memo/folder.errors.used_folder') if filters.count > 0
    errors.empty?
  end

  def folder_path
    id == 0 ? path : id.to_s
  end

  def direction
    %w(INBOX.Sent INBOX.Draft).include?(folder_path) ? 'from' : 'to'
  end

  def messages
    Gws::Memo::Message.folder(self)
  end

  def unseens
    messages.unseen(self.user_id)
  end

  def unseen?
    unseens.count > 0
  end

  class << self
    def allow(action, user, opts = {})
      super(action, user, opts).where(user_id: user.id)
    end

    def static_items(user)
      [
          self.new(name: I18n.t('gws/memo/folder.inbox'), path: 'INBOX', user_id: user.id),
          self.new(name: I18n.t('gws/memo/folder.inbox_trash'), path: 'INBOX.Trash', user_id: user.id),
          self.new(name: I18n.t('gws/memo/folder.inbox_draft'), path: 'INBOX.Draft', user_id: user.id),
          self.new(name: I18n.t('gws/memo/folder.inbox_sent'), path: 'INBOX.Sent', user_id: user.id),
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
