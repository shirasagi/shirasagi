class Gws::Survey::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Survey::CustomForm
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Fs::FilePreviewable

  attr_accessor :in_skip_notification_mail

  index(updated: -1)

  seqid :id
  field :name, type: String
  field :anonymous_state, type: String, default: 'disabled'

  permit_params :name

  validates :name, presence: true, length: { maximum: 80 }
  validates :anonymous_state, inclusion: { in: %w(disabled enabled), allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, 'column_values.text_index')
    end

    def enum_csv(params)
      Gws::Survey::FileEnumerator.new(self, params)
    end

    def aggregate
      select_like_columns = [ Gws::Column::Value::CheckBox, Gws::Column::Value::RadioButton, Gws::Column::Value::Select ]

      pipes = []
      pipes << { "$match" => self.all.selector }
      pipes << { "$unwind" => "$column_values" }
      pipes << { "$match" => { "column_values._type" => { "$in" => select_like_columns.map(&:name) } } }
      pipes << {
        "$project" => {
          "column_values.column_id" => 1,
          "column_values.values" => { "$ifNull" => [ "$column_values.values", [ "$column_values.value" ] ] }
        }
      }
      pipes << { "$unwind" => "$column_values.values" }
      pipes << {
        "$group" => {
          _id: { "column_id" => "$column_values.column_id", "value" => "$column_values.values" },
          count: { "$sum"=> 1 }
        }
      }

      self.collection.aggregate(pipes).to_a
    end
  end

  def anonymous?
    anonymous_state == 'enabled'
  end

  def file_previewable?(file, user:, member:)
    return false if user.blank?
    return false if column_values.where(file_ids: file.id).blank?

    form = self.form
    return true if form.allowed?(:read, user, site: self.site)

    if form.readable?(user, self.site)
      return true if user_id == user.id
      return true if form.file_public?
    end

    false
  end
end
