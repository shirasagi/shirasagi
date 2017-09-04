class Gws::Circular::Topic
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Board::Postable
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Board::Category

  store_in collection: 'gws_circular_topics'
  set_permission_name 'gws_circular_topics'

  field :due_date, type: DateTime
  field :mark_type, type: String, default: 'normal'

  embeds_ids :mark_users, class_name: 'Gws::User'

  permit_params :due_date, :mark_type, mark_user_ids: []

  validates :due_date, presence: true

  has_many :children,
           class_name: 'Gws::Circular::Post',
           dependent: :destroy,
           inverse_of: :parent,
           order: { created: -1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if sort_num = params[:sort].to_i
      criteria = criteria.order_by(sort_hash(sort_num))
    end

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end

    criteria
  }

  # 回覧板へのコメントを許可しているか？
  #
  # ・コメントを編集する権限を持っている
  # ・コメントを一度もしていない
  # ・ユーザーもしくはメンバーに含まれる
  #
  def permit_comment?(*args)
    opts = {
        user: user,
        site: site
    }.merge(args.extract_options!)

    return false unless Gws::Circular::Post.allowed?(:edit, opts[:user], site: opts[:site])
    return false if children.where(user_ids: opts[:user].id).exists?
    user_ids.include?(opts[:user].id) || member?(opts[:user])
  end

  def markable?(u=user)
    member?(u) && mark_user_ids.exclude?(u.id)
  end

  def marked_by(u=user)
    self.mark_user_ids = mark_user_ids << u.id if markable?(u)
    self
  end

  def unmarkable?(u=user)
    member?(u) && mark_user_ids.include?(u.id)
  end
  alias_method :marked?, :unmarkable?

  def unmarked_by(u=user)
    attributes[:mark_user_ids].delete(u.id) if unmarkable?(u)
    self
  end

  class << self
    def mark_type_options
      [
          ['通常閲覧', 'normal'],
          ['簡易閲覧', 'simple']
      ]
    end

    def sort_items
      [
          {
              key: :updated,
              order: -1,
              name: I18n.t('mongoid.attributes.ss/document.updated')
          },
          {
              key: :created,
              order: -1,
              name: I18n.t('mongoid.attributes.ss/document.created')
          }
      ]
    end

    def sort_hash(num=0)
      result = {}
      item = sort_items[num]
      result[item[:key]] = item[:order]
      result
    end

    def sort_options
      sort_items.map.with_index { |item, i| [item[:name], i] }
    end

    def to_csv
      CSV.generate do |data|
        data << %w(回覧id タイトル 返信id 状態 返信者名 返信欄 返信日時)

        each do |item|
          item.members.each do |member|
            post = item.children.where(user_id: member.id).first
            data << [
                item.id,
                item.name,
                post.try(:id),
                item.marked?(member),
                member.name,
                post.try(:text),
                post.try(:updated)
            ]
          end
        end
      end
    end
  end
end