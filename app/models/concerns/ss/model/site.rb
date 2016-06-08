module SS::Model::Site
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  class MultipleRootGroupsError < RuntimeError
  end

  included do
    store_in collection: "ss_sites"
    index({ host: 1 }, { unique: true })
    index({ domains: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :host, type: String
    field :domains, type: SS::Extensions::Words
    field :https, type: String, default: "disabled"
    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :host, :domains, :https, group_ids: []

    validates :name, presence: true, length: { maximum: 40 }
    validates :host, uniqueness: true, presence: true, length: { minimum: 3, maximum: 16 }

    validate :validate_domains, if: ->{ domains.present? }

    def domain
      domains[0]
    end

    def path
      "#{self.class.root}/" + host.split(//).join("/") + "/_"
    end

    def url
      domain.index("/") ? domain.sub(/^.*?\//, "/") : "/"
    end

    def full_url
      schema = (https == 'enabled') ? "https" : "http"
      "#{schema}://#{domain}/".sub(/\/+$/, "/")
    end

    def root_groups
      root_group_ids = groups.map do |group|
        group.root.id
      end.uniq.sort.to_a

      root_group_ids.map do |group_id|
        SS::Group.find group_id
      end
    end

    def root_group
      ret = root_groups
      if ret.length > 1
        raise MultipleRootGroupsError, "site: #{name} has multiple root groups"
      end
      ret.first
    end

    def https_options
      [
        [I18n.t("views.options.state.enabled"), "enabled"],
        [I18n.t("views.options.state.disabled"), "disabled"],
      ]
    end

    private
      def validate_domains
        errors.add :domains, :duplicate if self.class.ne(id: id).any_in(domains: domains).exists?
      end

    class << self
      def root
        "#{Rails.public_path}/sites"
      end

      def find_by_domain(host)
        site = SS::Site.find_by domains: host rescue nil
        site ||= SS::Site.first if Rails.env.development?
        site
      end
    end
  end

  module ClassMethods
      def search(params)
        criteria = self.where({})
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

end
