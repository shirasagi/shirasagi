class Gws::Memo::Folder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::FreePermission

  seqid :id
  field :name, type: String
  field :path, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true, uniqueness: { scope: :site_id }

  default_scope ->{ order_by order: 1 }

  def unseen?
    false
  end

  class << self
    def staticItems
      [
          self.new(name: '受信トレイ', path: 'INBOX'),
          self.new(name: 'ゴミ箱', path: 'INBOX.Trash'),
          self.new(name: '送信済み', path: 'INBOX.Sent')
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
