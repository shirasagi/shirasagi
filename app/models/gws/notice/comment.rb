class Gws::Notice::Comment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Addon::Markdown

  attr_accessor :cur_notice

  belongs_to :notice, class_name: 'Gws::Notice::Post'

  before_validation :set_notice_id, if: ->{ @cur_notice }

  validates :notice_id, presence: true
  validates :text, presence: true

  scope :and_notice, ->(notice) { where( notice_id: notice.id ) }

  private

  def set_notice_id
    self.notice_id ||= @cur_notice.id
  end
end
