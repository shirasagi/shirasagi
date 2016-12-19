module SS::Model::Site
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  class MultipleRootGroupsError < RuntimeError
  end

  included do
    store_in collection: "ss_sites"
    index({ host: 1 }, { unique: true })
    index({ domains_with_subdir: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :host, type: String
    field :domains, type: SS::Extensions::Words
    field :domains_with_subdir, type: Array
    field :subdir, type: String
    field :https, type: String, default: "disabled"
    field :public_path, type: String
    embeds_ids :groups, class_name: "SS::Group"

    attr_accessor :cur_domain

    permit_params :name, :host, :domains, :public_path, :https, :document_root, group_ids: []

    validates :name, presence: true, length: { maximum: 40 }
    validates :host, uniqueness: true, presence: true, length: { minimum: 3, maximum: 16 }

    validate :validate_domains, if: ->{ domains.present? }

    def domain
      cur_domain ? cur_domain : domains[0]
    end

    def domain_with_subdir
      subdir.present? ? "#{domain}/#{subdir}" : domain
    end

    def path
      subdir.present? ? "#{root_path}/#{subdir}" : root_path
    end

    def root_path
      root = "#{self.class.root}/"
      root += public_path.present? ? public_path : (host.split(//).join("/") + "/_")
    end

    def url
      subdir.present? ? "/#{subdir}/" : "/"
    end

    def root_url
      "/"
    end

    def full_url
      schema = (https == 'enabled') ? "https" : "http"
      root = "#{schema}://#{domain_with_subdir}/".sub(/\/+$/, "/")
      root
    end

    def full_root_url
      schema = (https == 'enabled') ? "https" : "http"
      root = "#{schema}://#{domain}/".sub(/\/+$/, "/")
      root
    end

    def filtered_domains
      filtered = []
      domains_with_subdir.each do |domain_with_subdir|
        if SS.config.kana.location.present?
          filtered << "#{domain_with_subdir}/".sub("/", "#{SS.config.kana.location}/")
        end

        if !mobile_disabled? && mobile_location.present?
          filtered << "#{domain_with_subdir}/".sub("/", "#{mobile_location}/")
        end
      end
      filtered
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
        self.domains = domains.uniq
        self.domains_with_subdir = []
        domains.each do |domain|
          self.domains_with_subdir << (subdir.present? ? "#{domain}/#{subdir}" : domain)
        end

        if self.class.ne(id: id).any_in(domains_with_subdir: domains_with_subdir).exists?
          errors.add :domains_with_subdir, :duplicate
        end

        if public_path.blank? && host.present?
          self.public_path = host.split(//).join("/") + "/_"
        end
      end

    class << self
      def root
        "#{Rails.public_path}/sites"
      end

      def find_by_domain(host, path = nil)
        sites = SS::Site.in(domains: host).to_a
        if sites.size <= 1
          site = sites.first
        else
          site = nil
          host_with_path = ::File.join(host, path.to_s)
          host_with_path += "/" if host_with_path !~ /\/$/
          depth = 0

          sites.each do |s|
            domains = s.domains_with_subdir + s.filtered_domains
            domains.each do |domain|
              if host_with_path =~ /^#{domain}\// && "#{domain}/".count("/")
                site = s
                depth = "#{domain}/".count("/")
              end
            end
          end
        end

        #site ||= SS::Site.first if Rails.env.development?
        site.cur_domain = host if site
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
          criteria = criteria.keyword_in params[:keyword], :host, :name
        end
        criteria
      end
  end

end
