module Gws::Discussion::Postable
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::GroupPermission

  included do
    store_in collection: "gws_discussion_posts"
    set_permission_name "gws_discussion_forums"

    attr_accessor :cur_site, :skip_descendants_updated

    seqid :id
    field :state, type: String, default: 'public'
    field :name, type: String
    field :depth, type: Integer
    field :descendants_updated, type: DateTime
    field :main_topic, type: String, default: "disabled"
    field :order, type: Integer, default: 0

    belongs_to :forum, class_name: "Gws::Discussion::Post", inverse_of: :forum_descendants
    belongs_to :topic, class_name: "Gws::Discussion::Post", inverse_of: :descendants
    belongs_to :parent, class_name: "Gws::Discussion::Post", inverse_of: :children

    has_many :forum_descendants, class_name: "Gws::Discussion::Post", dependent: :destroy, inverse_of: :forum,
      order: { created: -1 }
    has_many :descendants, class_name: "Gws::Discussion::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: -1 }
    has_many :children, class_name: "Gws::Discussion::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: -1 }

    permit_params :name, :order

    before_validation :set_depth

    validates :name, presence: true, length: { maximum: 80 }

    before_save :set_descendants_updated, if: -> { !skip_descendants_updated }
    after_save :update_topic_descendants_updated, if: -> { topic_id.present? && !skip_descendants_updated }
    after_save :update_forum_descendants_updated, if: -> { forum_id.present? && !skip_descendants_updated }

    scope :topic, ->{ exists parent_id: false }
    scope :topic_comments, ->(topic) { where topic_id: topic.id }
    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
      criteria
    }
  end

  def root_post
    parent.nil? ? self : parent.root_post
  end

  def comment?
    parent_id.present?
  end

  def main_topic_options
    [
      [I18n.t("ss.options.state.disabled"), "disabled"],
      [I18n.t("ss.options.state.enabled"), "enabled"],
    ]
  end

  def main_topic?
    main_topic == "enabled"
  end

  def new_flag?
    descendants_updated > Time.zone.now - site.discussion_new_days.day
  end

  def save_clone(new_parent = nil)
    post = Gws::Discussion::Base.new
    post.attributes = self.attributes

    post.id = nil
    post.created = post.updated = Time.zone.now
    post.released = nil
    post.descendants_updated = nil

    post.state = "closed" if post.depth == 1
    post.parent = new_parent if new_parent

    if respond_to?(:files)
      file_ids = []
      files.each do |f|
        file = SS::File.new
        file.attributes = f.attributes
        file.id = nil
        file.in_file = f.uploaded_file
        file.user_id = @cur_user.id if @cur_user

        file.save!
        file_ids << file.id
      end
      post.file_ids = file_ids
    end
    post.skip_descendants_updated = true
    post.save!

    children.each { |c| c.save_clone(post) }
    post
  end

  private

  def set_depth
    self.depth = parent ? parent.depth + 1 : 1
  end

  def set_descendants_updated
    self.descendants_updated = updated
  end

  def update_topic_descendants_updated
    topic.set descendants_updated: updated if topic
  end

  def update_forum_descendants_updated
    forum.set descendants_updated: updated if forum
  end
end
