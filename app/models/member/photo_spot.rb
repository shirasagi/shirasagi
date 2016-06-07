class Member::PhotoSpot
  include Cms::Model::Page
  include Member::Addon::Photo::Spot
  include Cms::Addon::Release
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "member_photos"

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "member/photo_spot") }

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
