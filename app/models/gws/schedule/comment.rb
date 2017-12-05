class Gws::Schedule::Comment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Schedule
  include SS::Addon::Markdown

  validates :text, presence: true

  delegate :subscribed_users, to: :schedule
end
