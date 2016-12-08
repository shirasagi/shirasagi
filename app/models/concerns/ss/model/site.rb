module SS::Model::Site
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  class MultipleRootGroupsError < RuntimeError
  end

  included do
    store_in collection: "ss_sites"
    index({ host: 1 }, { unique: true })
    index({ root_urls: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :host, type: String
    field :root_urls, type: SS::Extensions::Words
    field :domains, type: Array
    field :subdirs, type: Array
    field :https, type: String, default: "disabled"
    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :host, :root_urls, :https, group_ids: []

    validates :name, presence: true, length: { maximum: 40 }
    validates :host, uniqueness: true, presence: true, length: { minimum: 3, maximum: 16 }

    validate :validate_root_urls, if: ->{ root_urls.present? }

    def domain
      domains[0]
    end

    def subdir(domain = nil)
      return subdirs[0] unless domain

      i = domains.index(domain)
      return nil unless i
      subdirs[i]
    end

    def root_path
      "#{self.class.root}/" + host.split(//).join("/") + "/_"
    end

    def path
      subdir.present? ? "#{root_path}/#{subdir}" : root_path
    end

    def url
      root = domain.index("/") ? domain.sub(/^.*?\//, "/") : "/"
      root += "#{subdir}/" if subdir.present?
      root
    end

    def full_url
      schema = (https == 'enabled') ? "https" : "http"
      root = "#{schema}://#{domain}/".sub(/\/+$/, "/")
      root += "#{subdir}/" if subdir.present?
      root
    end

    def filtered_root_urls
      urls = []
      root_urls.each do |root_url|
        if SS.config.kana.location.present?
          urls << root_url.sub("/", "#{SS.config.kana.location}/")
        end

        if !mobile_disabled? && mobile_location.present?
          urls << root_url.sub("/", "#{mobile_location}/")
        end
      end
      urls
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
      def validate_root_urls
        self.root_urls = root_urls.map do |root_url|
          (root_url =~ /\/$/) ? root_url : "#{root_url}/"
        end.uniq

        if self.class.ne(id: id).any_in(root_urls: root_urls).exists?
          errors.add :domains, :duplicate
          return
        end

        self.domains = []
        self.subdirs = []
        root_urls.each do |root_url|
          root_url = root_url.split(/\//)
          self.domains << root_url.shift
          self.subdirs << root_url.join("/").presence
        end
      end

    class << self
      def root
        "#{Rails.public_path}/sites"
      end

      def find_by_domain(host, path = nil)
        sites = SS::Site.in(domains: host)
        site = nil
        if sites.count <= 1
          site = sites.first
        else
          url = "#{host}#{path}"
          url = "#{url}/" if url !~ /\/$/
          depth = 0

          sites.each do |s|
            root_urls = s.root_urls + s.filtered_root_urls
            root_urls.each do |root_url|
              if url =~ /^#{root_url}/ && url.count("/") > depth
                site = s
                depth = root_url.count("/")
              end
            end
          end
        end

        #site ||= SS::Site.first if Rails.env.development?
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
