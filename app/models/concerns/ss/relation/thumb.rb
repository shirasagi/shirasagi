module SS::Relation::Thumb
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    cattr_accessor(:thumbs_resizing) { {} }

    has_many :thumbs, class_name: "SS::ThumbFile", foreign_key: :original_id, dependent: :destroy
    after_save :destroy_thumbs, if: -> { in_file || resizing }
    after_save :save_thumbs, if: -> { image? }

    thumb_size [120, 90]
  end

  module ClassMethods
    private
      def thumb_size(size)
        add_thumb_size(:normal, size)
      end

      def add_thumb_size(name, size)
        thumbs_resizing[name] = size
      end
  end

  def thumb(key = nil)
    if key.nil?
      normal = thumbs.where(image_size_name: :normal).first
      normal ? normal : thumbs.first
    elsif key.kind_of?(Array)
      thumbs.where(image_size: key).first
    else
      thumbs.where(image_size_name: key).first
    end
  end

  def thumb_url
    thumb ? thumb.url : super
  end

  def destroy_thumbs
    return if thumbs.blank?

    result = thumbs.destroy_all
    reload
    result
  end

  ## generate first thumb file
  def generate_public_file(*args)
    super
    thumb.generate_public_file if thumb
  end

  def remove_public_file(*args)
    super
    thumb.remove_public_file if thumb
  end

  private
    def save_thumbs
      thumbs_was = thumbs.map { |t| [t.image_size, t] }.to_h
      thumbs_resizing = self.class.thumbs_resizing
      thumbs_resizing = thumbs_resizing.symbolize_keys.compact
      thumbs_resizing = thumbs_resizing.invert.invert #delete duplicate values

      thumbs_resizing.each do |name, size|
        file = thumbs_was.delete(size)
        if file
          if state_changed? || filename_changed? || site_id_changed?
            file.update_attributes(filename: filename, state: state, site_id: site_id)
          end
          file.set(image_size_name: name) if name != file.image_size_name
        else
          file = SS::ThumbFile.new
          file.in_file         = uploaded_file
          file.resizing        = size
          file.original_id     = id
          file.state           = state
          file.filename        = file.in_file.original_filename
          file.image_size      = size
          file.image_size_name = name
          file.user_id         = user_id
          file.site_id         = site_id if respond_to?(:site_id)
          file.save
        end
      end

      thumbs_was.values.each(&:destroy)
      reload
    end
end
