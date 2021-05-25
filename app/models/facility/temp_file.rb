class Facility::TempFile
  include SS::Model::File
  include SS::UserPermission

  default_scope ->{ where(model: "ss/temp_file") }

  validate :validate_image, if: ->{ in_file.present? }

  private

  def validate_image
    return if SS.config.ss.sanitizer_input
    errors.add :in_file, :image unless image?
  end
end
