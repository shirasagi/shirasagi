class Opendata::Member
  include Cms::Member::Model
  include SS::Relation::File

  belongs_to_file :icon
  permit_params :in_icon

  has_one :points, primary_key: :member_id, class_name: "Opendata::MemberNotice",
    dependent: :destroy

  validate "convert_icon", if: ->{ in_icon.present? }

  def convert_icon
    file = send("in_icon")

    begin
      require 'RMagick'
      image = Magick::Image.from_blob(in_icon.read).shift
      image = image.resize_to_fill 114, 114 if image.columns > 114 || image.rows > 114
    rescue
      return errors.add :icon_id, :invalid
    end

    def image.size
      filesize
    end
    def image.content_type
      mime_type
    end
    def image.original_filename=(filename)
      @filename = filename
    end
    def image.original_filename
      @filename
    end
    def image.read
      to_blob
    end

    image.original_filename = in_icon.original_filename

    self.in_icon = image
  end
end
