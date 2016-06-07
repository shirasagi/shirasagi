class Member::TempFile
  include SS::Model::File
  include SS::Relation::Thumb
  include Cms::Reference::Member
  include Cms::MemberPermission

  default_scope ->{ where(model: "member/temp_file") }

  #validate :validate_member_filesize, if: ->{ in_file.present? && in_files.blank? }

  #def validate_member_filesize
  #  return unless member
  #  if (size + Member::File.member(member).sum(&:size)) > (1024 * 1024 * 100)
  #    errors.add :base, "全ファイル容量が100MBを超えている為、アップロードできません。"
  #  end
  #end
end
