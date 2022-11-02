module Gws::Addon::Workload::CommentPost
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :comments, class_name: 'Gws::Workload::WorkComment', dependent: :destroy, validate: false
    before_validation :set_comments_total
    before_validation :set_due_end_on
  end

  public

  def last_comment
    comments.exists(achievement_rate: true).last
  end

  def finished?
    work_state == 'finished'
  end

  private

  def set_comments_total
    self.achievement_rate = last_achievement_rate || 0
    self.worktime_minutes = comments.pluck(:worktime_minutes).map(&:to_i).sum
    set_work_state
  end

  def set_work_state
    if achievement_rate.blank? || achievement_rate <= 0
      self.work_state = "unfinished"
    elsif achievement_rate >= 100
      self.work_state = "finished"
    else
      self.work_state = "progressing"
    end
  end

  def set_due_end_on
    return if due_date.nil?
    return if due_start_on.nil?
    return if due_end_on
    return if achievement_rate < 100

    today = Time.zone.today
    if today > due_date
      self.due_end_on = due_date
    elsif today < due_start_on
      self.due_end_on = due_start_on
    else
      self.due_end_on = today
    end
  end

  def last_achievement_rate
    return if last_comment.blank?
    last_comment.achievement_rate
  end
end
