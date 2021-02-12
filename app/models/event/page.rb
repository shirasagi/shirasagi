class Event::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Cms::Addon::EditLock
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Cms::Addon::TwitterPoster
  include Cms::Addon::LinePoster
  include Gravatar::Addon::Gravatar
  include Cms::Addon::RedirectLink
  include Cms::Addon::Body
  include Cms::Addon::File
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Event::Addon::Body
  include Event::Addon::IcalLink
  include Cms::Addon::AdditionalInfo
  include Event::Addon::Date
  include Map::Addon::Page
  include Event::Addon::Facility
  include Cms::Addon::Tag
  include Cms::Addon::RelatedPage
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Event::Addon::Csv::Page
  include Cms::Addon::ForMemberPage

  set_permission_name "event_pages"

  after_save :new_size_input, if: ->{ @db_changes }

  def new_size_input
    html = self.try(:render_html).presence || self.try(:html)
    file_bytesize = SS::File.where(owner_item_type: self.class.name, owner_item_id: self.id).sum(:size)
    self.set(size: html.try(:bytesize).to_i + file_bytesize)
  end

  default_scope ->{ where(route: "event/page") }
end
