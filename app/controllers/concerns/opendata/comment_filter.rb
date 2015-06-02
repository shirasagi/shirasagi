module Opendata::CommentFilter
  extend ActiveSupport::Concern

  private
    def update_commented_count(member_ids, count)
      member_ids.each do |member_id|
        notice = Opendata::MemberNotice.where({site_id: @cur_site.id, member_id: member_id}).first
        if notice
          notice.commented_count += count
          notice.save
        else
          notice_new = { site_id: @cur_site.id, member_id: member_id, commented_count: 1 }
          Opendata::MemberNotice.new(notice_new).save
        end
      end
    end

  public
    def update_member_notices(idea)

      except_member_ids = []
      except_member_ids << @cur_member.id if @cur_member
      except_member_ids << idea.member_id if idea.member_id

      member_ids = []
      other_comments = Opendata::IdeaComment.where({idea_id: idea.id})
      other_comments.each do |other_comment|
        other_member_id = other_comment.member_id
        if other_member_id && except_member_ids.include?(other_member_id) == false
          member_ids << other_comment.member_id
        end
      end

      if @cur_member
        if idea.member_id && idea.member_id != @cur_member.id
          member_ids << idea.member_id
        end
      else
        if idea.member_id
          member_ids << idea.member_id
        end
      end

      update_commented_count(member_ids.uniq, 1)

    end

end