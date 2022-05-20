module Cms::Line::Richmenu
  class Menu
    include SS::Document
    include SS::Reference::User
    include SS::Reference::Site
    include SS::Relation::File
    include Cms::Addon::Line::Richmenu::Area
    include Cms::SitePermission
    include Fs::FilePreviewable

    set_permission_name "cms_line_services", :use

    seqid :id
    field :name
    field :order, type: Integer, default: 0
    field :target, type: String
    field :area_size, type: Integer
    field :width, type: Integer
    field :height, type: Integer
    field :chat_bar_text, type: String
    permit_params :name, :order, :target, :area_size, :width, :height, :chat_bar_text

    belongs_to :group, class_name: "Cms::Line::Richmenu::Group", inverse_of: :richmenus
    belongs_to_file :image, class_name: "Cms::Line::File"

    # https://developers.line.biz/ja/reference/messaging-api/#rich-menu-object
    validates :name, presence: true
    validates :group_id, presence: true
    validates :area_size, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 20 }
    validates :width, numericality: { greater_than_or_equal_to: 800, less_than_or_equal_to: 2500 }
    validates :height, numericality: { greater_than_or_equal_to: 250 }
    validates :chat_bar_text, presence: true, length: { maximum: 14 }
    validate :validate_image
    validate :validate_target

    default_scope -> { order_by(order: 1) }

    private

    def set_updated
      super
      # 画像、タップ領域に変更を加えた際に、updated を更新して、APIに新規登録したい
      self.updated = updated ? Time.zone.now : created if in_image
    end

    def validate_target
      if target.blank?
        errors.add :target, :blank
        return
      end
      if target == "default" || target == "member"
        if group.menus.select { |menu| menu.id != id && menu.target == target }.present?
          errors.add :target, :richmenu_target_taken
        end
      end
    end

    def validate_image
      return if image
      return if in_image
      errors.add :image_id, :blank
    end

    public

    def order
      value = self[:order].to_i
      value < 0 ? 0 : value
    end

    def root_owned?(user)
      true
    end

    def file_previewable?(file, user:, member:)
      true
    end

    def richmenu_areas
      areas.take(area_size)
    end

    def richmenu_alias
      "ss_richmenu_#{id}"
    end

    def use_richmenu_alias?
      richmenu_areas.select { |area| area.use_richmenu_alias? }.present?
    end

    def richmenu_object
      {
        size: {
          width: width,
          height: height
        },
        selected: false,
        name: name,
        chatBarText: chat_bar_text,
        areas: richmenu_areas.map { |area| area.richmenu_object }
      }
    end

    class << self
      def search(params)
        criteria = all
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.search_text params[:name]
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name
        end
        criteria
      end
    end
  end
end
