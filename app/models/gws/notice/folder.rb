class Gws::Notice::Folder
  include SS::Document
  include Gws::Model::Folder
  include Gws::Addon::Notice::ResourceLimitation
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  def notices
    Gws::Notice::Post.all.site(site).where(folder_id: id)
  end

  def reclaim!
    set(
      notice_total_body_size: notices.pluck(:text).map(&:size).sum,
      notice_total_file_size: SS::File.in(id: notices.pluck(:file_ids).flatten).sum(:size)
    )
  end
end
