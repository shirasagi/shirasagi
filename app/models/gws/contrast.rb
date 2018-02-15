class Gws::Contrast
  extend SS::Translation
  include SS::Document
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_contrasts', :edit

  field :name, type: String
  field :order, type: Integer
  field :state, type: String, default: 'public'
  field :text_color, type: String
  field :color, type: String
  permit_params :name, :order, :state, :text_color, :color

  validates :name, presence: true, length: { maximum: 40 }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :text_color, presence: true, if: -> { state == 'public' }
  validates :color, presence: true, if: -> { state == 'public' }

  scope :and_public, ->{ where state: 'public' }

  def state_options
    %w(public closed).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  class << self
    def search(params = {})
      all.search_name(params).search_keyword(params)
    end

    def search_name(params = {})
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params = {})
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :name
    end
  end
end
