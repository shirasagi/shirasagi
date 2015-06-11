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
    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :host, :domains, group_ids: []

    has_many :pages, class_name: "Cms::Page", dependent: :destroy
    has_many :nodes, class_name: "Cms::Node", dependent: :destroy
    has_many :parts, class_name: "Cms::Part", dependent: :destroy
    has_many :layouts, class_name: "Cms::Layout", dependent: :destroy

    validates :name, presence: true, length: { maximum: 40 }
    validates :host, uniqueness: true, presence: true, length: { minimum: 3, maximum: 16 }

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
      "http://#{domain}/".sub(/\/+$/, "/")
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
end
