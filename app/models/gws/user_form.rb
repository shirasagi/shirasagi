class Gws::UserForm
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::History

  set_permission_name 'gws_user_forms', :edit

  field :memo, type: String
  has_many :columns, class_name: 'Gws::Column::Base', dependent: :destroy, inverse_of: :form, as: :form

  permit_params :memo

  delegate :build_column_values, to: :columns

  def reference_name
    self.class.model_name.human
  end
end
