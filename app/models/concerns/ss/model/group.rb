module SS::Model::Group
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Scope::ActivationDate
  include SS::Addon::Ldap::Group
  include SS::Fields::DependantNaming
  include SS::Liquidization

  attr_accessor :in_password

  included do
    store_in collection: "ss_groups"
    index({ name: 1 }, { unique: true })
    index({ domains: 1 }, { unique: true, sparse: true })

    define_model_callbacks :chorg

    seqid :id
    field :name, type: String
    field :order, type: Integer
    field :activation_date, type: DateTime
    field :expiration_date, type: DateTime
    field :domains, type: SS::Extensions::Words
    field :gws_use, type: String
    field :upload_policy, type: String
    # 書き出しパスのID; public/gws/ 以下のフォルダー名Add commentMore actions
    field :path_id, type: String

    permit_params :name, :order, :activation_date, :expiration_date, :domains, :gws_use
    permit_params :path_id

    default_scope -> { order_by(order: 1, name: 1) }

    validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
    validates :domains, domain: true
    validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
    validates :activation_date, datetime: true
    validates :expiration_date, datetime: true
    validates :gws_use, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :path_id, format: { with: /\A[a-z][a-z0-9]+\z/, allow_blank: true }
    validate :validate_name
    validate :validate_domains, if: ->{ domains.present? }

    liquidize do
      export as: :to_s do
        name
      end
      export :id
      export :name
      export :full_name
      export :section_name
      export :trailing_name
      export :last_name do
        name.split("/").last
      end
    end
  end

  module ClassMethods
    def root
      "#{Rails.public_path}/gws"
    end
    def in_group(group)
      all.where("$and" => [{ name: /^#{::Regexp.escape(group.name)}(\/|$)/ }])
    end

    def in_groups(groups)
      return none if groups.blank?
      return in_group(groups.first) if groups.count == 1

      names = groups.pluck(:name)
      conditions = names.map { { name: /^#{::Regexp.escape(_1)}(\/|$)/ } }
      all.where("$and" => [{ "$or" => conditions }])
    end

    def organizations
      all.where("$and" => [{ :name.not => /\// }])
    end

    def and_gws_use
      conditions = [
        { :gws_use.exists => false },
        { :gws_use.ne => "disabled" },
      ]
      all.where("$and" => [{ "$or" => conditions }])
    end

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

    def tree_sort(options = {})
      SS::GroupTreeList.build self, options
    end

    def roots
      self.not(name: /\//)
    end
  end

  def full_name
    name.tr("/", " ")
  end

  def section_name
    return name unless name.include?('/')
    name.split("/")[1..-1].join(' ')
  end

  def trailing_name
    @trailing_name ||= name.split("/")[depth..-1].join("/")
  end

  def root
    parts = name.try(:split, "/") || []
    return self if parts.length <= 1

    0.upto(parts.length - 1) do |c|
      ret = self.class.where(name: parts[0..c].join("/")).first
      return ret if ret.present?
    end
    nil
  end
  alias organization root

  def root?
    id == root.id
  end
  alias organization? root?

  def descendants
    self.class.where(name: /^#{::Regexp.escape(name)}\//)
  end

  def descendants_and_self
    self.class.in_group(self)
  end

  def parents
    return self.class.none unless name.include?("/")

    n = nil
    parent_names = name.sub("/#{trailing_name}", "").split(/\//)
    parent_names = parent_names.map { |name| n = (n ? "#{n}/#{name}" : name) }
    self.class.in(name: parent_names)
  end

  # Soft delete
  def disable
    return false unless super
    descendants.each { |item| item.disable }
    true
  end

  def depth
    @depth ||= begin
      count = 0
      full_name = ""
      name.split('/').map do |part|
        full_name << "/" if full_name.present?
        full_name << part

        break if name == full_name

        found = self.class.where(name: full_name).first
        break if found.blank?

        count += 1
      end
      count
    end
  end

  def domain
    domains[0]
  end

  def domain_editable?
    !new_record? && !name_was.to_s.include?('/')
  end

  def gws_use_options
    %w(disabled enabled).map { |v| [ I18n.t("ss.options.gws_use.#{v}"), v ] }
  end

  def gws_use?
    gws_use.blank? || gws_use != "disabled"
  end

  def upload_policy_options
    SS::UploadPolicy.upload_policy_options
  end

  # Cast
  def cms_group
    is_a?(Cms::Group) ? self : Cms::Group.find(id)
  end

  def gws_group
    is_a?(Gws::Group) ? self : Gws::Group.find(id)
  end

  def webmail_group
    is_a?(Webmail::Group) ? self : Webmail::Group.find(id)
  end

  def root_path
    return if path_id.blank?
    "#{self.class.root}/#{path_id}"
  end

  private

  def validate_name
    if name =~ /\/$/ || name =~ /^\// || name =~ /\/\//
      errors.add :name, :invalid
    end
  end

  def validate_domains
    self.domains = domains.uniq.reject(&:blank?)
    return if self.domains.blank?

    if name.include?('/')
      errors.add :domains, I18n.t('gws.errors.allowed_domains_only_root')
    elsif self.class.ne(id: id).any_in(domains: self.domains).exists?
      errors.add :domains, :duplicate
    end
  end
end
