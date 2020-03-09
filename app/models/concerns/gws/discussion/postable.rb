module Gws::Discussion::Postable
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Member
  include Gws::GroupPermission
  include Fs::FilePreviewable

  included do
    store_in collection: "gws_discussion_posts"

    attr_accessor :cur_site, :skip_descendants_updated

    seqid :id
    field :state, type: String, default: 'public'
    field :name, type: String
    field :depth, type: Integer
    field :descendants_updated, type: DateTime
    field :main_topic, type: String, default: "disabled"
    field :permit_comment, type: String, default: "allow"
    field :permanently, type: String, default: "disabled"
    field :forum_quota, type: Integer, default: nil
    field :topic_quota, type: Integer, default: nil
    field :order, type: Integer, default: 0

    belongs_to :forum, class_name: "Gws::Discussion::Forum", inverse_of: :forum_descendants
    belongs_to :topic, class_name: "Gws::Discussion::Topic", inverse_of: :descendants
    belongs_to :parent, class_name: "Gws::Discussion::Post", inverse_of: :children

    has_many :forum_descendants, class_name: "Gws::Discussion::Post", dependent: :destroy, inverse_of: :forum,
      order: { created: -1 }
    has_many :descendants, class_name: "Gws::Discussion::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: -1 }
    has_many :children, class_name: "Gws::Discussion::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: -1 }

    permit_params :name, :order, :permit_comment, :permanently, :forum_quota, :topic_quota

    before_validation :set_depth

    validates :name, presence: true, length: { maximum: 80 }

    before_save :set_descendants_updated, if: -> { !skip_descendants_updated }
    after_save :update_topic_descendants_updated, if: -> { topic_id.present? && !skip_descendants_updated }
    after_save :update_forum_descendants_updated, if: -> { forum_id.present? && !skip_descendants_updated }

    scope :forum, ->{ exists parent_id: false }
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

  def current_forum
    depth == 1 ? self : forum
  end

  def current_topic
    return nil unless comment?

    depth == 2 ? self : parent
  end

  def comment?
    parent_id.present?
  end

  def main_topic?
    main_topic == "enabled"
  end

  def permit_comment?
    (permit_comment == "allow") && !permanently?
  end

  def permanently?
    permanently == "enabled"
  end

  def main_topic_options
    [
      [I18n.t("ss.options.state.disabled"), "disabled"],
      [I18n.t("ss.options.state.enabled"), "enabled"],
    ]
  end

  def permit_comment_options
    [
      [I18n.t("gws/discussion.options.permit_comment.allow"), "allow"],
      [I18n.t("gws/discussion.options.permit_comment.deny"), "deny"],
    ]
  end

  def permanently_options
    [
      [I18n.t("ss.options.state.disabled"), "disabled"],
      [I18n.t("ss.options.state.enabled"), "enabled"],
    ]
  end

  def new_flag?
    created > Time.zone.now - site.discussion_new_days.day
  end

  def save_clone(new_parent = nil)
    post = self.class.new
    post.attributes = self.attributes

    post.id = nil
    post.created = post.updated = Time.zone.now
    post.released = nil if respond_to?(:released)
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

    children.order(id: 1).each { |c| c.save_clone(post) }
    post
  end

  def member?(*args)
    if forum.present? && forum_id != id
      forum.member?(*args)
    end

    super
  end

  def file_previewable?(file, user:, member:)
    return false if user.blank?
    return false if !file_ids.include?(file.id)

    if forum.present? && forum_id != id
      return true if forum.allowed?(:read, user, site: @cur_site || site)
      return true if forum.member?(user)
    else
      return true if self.allowed?(:read, user, site: @cur_site || site)
      return true if self.member?(user)
    end

    false
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
