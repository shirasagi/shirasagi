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
    field :mypage_scheme, type: String, default: 'http'
    field :mypage_domain, type: String
    field :upload_policy, type: String
    embeds_ids :groups, class_name: "SS::Group"
    belongs_to :parent, class_name: "SS::Site"

    attr_accessor :cur_domain

    permit_params :name, :host, :domains, :subdir, :parent_id, :https, :document_root, group_ids: []
    permit_params :mypage_scheme, :mypage_domain
    validates :name, presence: true, length: { maximum: 40 }
    validates :host, uniqueness: true, presence: true, length: { minimum: 3, maximum: 16 }
    validates :domains, presence: true, domain: true
    validates :subdir, presence: true, if: -> { parent.present? }
    validates :parent_id, presence: true, if: -> { subdir.present? }

    validate :validate_domains, if: ->{ domains.present? }

    after_save :move_public_file

    def domain
      cur_domain || domains[0]
    end

    def domain_with_subdir
      subdir.present? ? "#{domain}/#{subdir}" : domain
    end

    def path
      subdir.present? ? "#{root_path}/#{subdir}" : root_path
    end

    def root_path
      if parent
        parent.root_path
      else
        "#{self.class.root}/" + (host.split(//).join("/") + "/_")
      end
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

    def mypage_full_url
      if mypage_domain.present?
        "#{mypage_scheme.presence || 'http'}://#{mypage_domain}/".sub(/\/+$/, "/")
      else
        full_root_url
      end
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
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"],
      ]
    end

    def mypage_scheme_options
      [
        %w(http http),
        %w(https https),
      ]
    end

    def upload_policy_options
      SS::UploadPolicy.upload_policy_options
    end

    def same_domain_sites
      @_same_domain_sites ||= SS::Site.all.select { |site| self.full_root_url == site.full_root_url }
    end

    def same_domain_site_from_path(path)
      sites = same_domain_sites.sort_by { |site| site.url.count("/") }.reverse
      sites.each do |site|
        if path =~ /^#{site.url}/
          return site
        end
      end
      return nil
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
    end

    def move_public_file
      src_site = self.dup
      src_site.host = host_was
      src_site.subdir = subdir_was
      src_site.parent_id = parent_id_was

      return if src_site.host.blank?
      return if path == src_site.path
      return if Fs.exists?(path)
      return if !Fs.exists?(src_site.path)

      if path.include?(src_site.path)
        temp_path = src_site.path.sub(self.class.root, "#{self.class.root}/temp")
        Fs.mkdir_p(File.dirname(temp_path))
        Fs.mv(src_site.path, src_site.path.sub(self.class.root, "#{self.class.root}/temp"))
        FileUtils.rmdir(File.dirname(src_site.path), parents: true) if Dir.empty?(File.dirname(src_site.path))
        Fs.mkdir_p(File.dirname(path))
        FileUtils.rmdir(path, parents: true) if Fs.exists?(path) && Dir.empty?(path)
        Fs.mv(temp_path, path) if Fs.exists?(temp_path)
      else
        Fs.mkdir_p(File.dirname(path))
        Fs.mv(src_site.path, path)
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
            domains = s.domains_with_subdir
            domains.each do |domain|
              if host_with_path =~ /^#{domain}\// && "#{domain}/".count("/") > depth
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
        criteria = criteria.keyword_in params[:keyword], :host, :name, :domains
      end
      criteria
    end
  end

end
