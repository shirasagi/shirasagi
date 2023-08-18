class Jmaxml::Action::Base
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  store_in collection: "jmaxml_actions"
  set_permission_name "cms_tools", :use

  attr_accessor :in_type

  field :name, type: String
  validates :name, presence: true, length: { maximum: 40 }
  permit_params :in_type, :name

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end

  def type_options
    sub_classes = [
      Jmaxml::Action::PublishPage,
      Jmaxml::Action::SendMail,
      Jmaxml::Action::SwitchUrgency ]
    sub_classes.map do |v|
      [ v.model_name.human, v.name ]
    end
  end

  def execute(page, context)
    raise NotImplementedError
  end
end
