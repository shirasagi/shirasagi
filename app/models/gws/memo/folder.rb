class Gws::Memo::Folder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  set_permission_name 'gws_memo_messages'

  seqid :id
  field :name, type: String
  field :path, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order, :path

  validates :name, presence: true, uniqueness: { scope: :site_id }

  default_scope ->{ order_by order: 1 }

  def direction
    %w(INBOX.Sent INBOX.Draft).include?(path) ? 'from' : 'to'
  end

  def messages(uid=user_id)
    Gws::Memo::Message.where("#{direction}.#{uid}": path)
  end

  def unseen?
    false
  end

  class << self
    def allow_condition(action, user, opts = {})
        { user_ids: user.id }
    end

    def static_items
      [
          self.new(name: '受信トレイ', path: 'INBOX'),
          self.new(name: 'ゴミ箱', path: 'INBOX.Trash'),
          self.new(name: '下書き', path: 'INBOX.Draft'),
          self.new(name: '送信済みトレイ', path: 'INBOX.Sent'),
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
