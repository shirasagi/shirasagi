class SS::LinkItem
  extend SS::Translation
  include SS::Document
  include SS::Relation::File

  embedded_in :parent
  field :name, type: String
  field :url, type: String
  field :target, type: String
  field :state, type: String
  belongs_to_file :file, static_state: SS::Relation::File::DEFAULT_FILE_STATE, accepts: SS::File::IMAGE_FILE_EXTENSIONS

  class << self
    def target_options
      %w(_self _blank).map do |v|
        [ I18n.t("ss.options.link_target.#{v}"), v ]
      end
    end

    def state_options
      %w(show hide).map do |v|
        [ I18n.t("ss.options.state.#{v}"), v ]
      end
    end
  end

  delegate :target_options, :state_options, to: :class
end
