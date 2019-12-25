class Cms::GenerateTask
  include SS::Model::Task

  belongs_to :node, class_name: "Cms::Node"

  field :generate_key, type: String

  validates :site_id, presence: true

  def name
    generate_key.present? ? "#{super}(#{generate_key})" : super
  end
end
