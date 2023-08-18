module Gws::Bookmark
  class Folder
    include SS::Document
    include Gws::Model::Folder
    include Gws::Addon::History
    include Gws::SitePermission

    set_permission_name 'gws_bookmarks', :edit

    field :folder_type, type: String, default: "general"
    has_many :items, class_name: 'Gws::Bookmark::Item', dependent: :destroy

    validates :folder_type, presence: true
    validates :in_parent, presence: true, if: ->{ general_folder? }
    validate :validate_destination

    default_scope ->{ order_by(depth: 1, order: 1) }

    def dependant_scope
      s = @cur_site || site
      u = @cur_user || user

      return self.class.none if s.nil? || u.nil?
      self.class.site(s).user(u)
    end

    def specified_folder?
      folder_type == "specified"
    end

    def general_folder?
      !specified_folder?
    end

    private

    # validate : フォルダーを登録/編集/移動した際に、移動先が妥当か検証する、前提として in_parent から name が設定されていること
    def validate_destination
      self.site ||= cur_site
      self.user ||= cur_user

      return if errors.present?
      return if site.nil?
      return if user.nil?
      return if in_basename.blank?

      folders = self.class.site(site).user(user).nin(id: id).to_a
      if folders.find { |item| item.name == name }
        errors.add :base, :same_folder_exists
      end

      return if name_was.blank?

      if name.start_with?(name_was + "/")
        errors.add :base, :subfolder_of_itself
      end
    end

    # before_destroy : ブックマークフォルダーは下階層があっても削除できる、階層のフォルダーを全て削除する
    def validate_children
      folders.each(&:destroy)
    end

    class << self
      def default_root_name
        name = SS.config.gws.bookmark["root_folder"].presence rescue nil
        name ||= I18n.t("modules.gws/bookmark")
        name
      end
    end
  end
end
