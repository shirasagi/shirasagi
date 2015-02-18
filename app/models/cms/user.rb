class Cms::User
  include SS::User::Model
  include Cms::Addon::Role
  include Cms::Permission

  set_permission_name "cms_users", :edit

  attr_accessor :cur_site
  attr_accessor :in_uid

  permit_params :in_uid

  validate :validate_groups
  validates :email, presence: true, if: ->{ accounts.blank? }
  validates :accounts, presence: true, if: ->{ email.blank? }

  before_validation :set_accounts

  scope :site, ->(site) { self.in(group_ids: Cms::Group.site(site).pluck(:id)) }

  public
    def allowed?(action, user, opts = {})
      return true if Sys::User.allowed?(action, user)
      super
    end

    def long_name
      uid = uid_of(cur_site.root_group) if cur_site.present?
      uid ||= email.split("@")[0] if email.present?
      if uid.present?
        "#{name}(#{uid})"
      else
        "#{name}"
      end
    end

    def in_uid
      @in_uid || cur_accounts.first.try(:uid)
    end

    def in_uid=(uid)
      @in_uid = uid
    end

  private
    def validate_groups
      self.errors.add :group_ids, :blank if groups.blank?
    end

    def cur_root_group
      cur_site.try(:root_group)
    end

    def cur_accounts
      root_group_id = cur_root_group.try(:id)
      accounts.select do |account|
        account.group_id == root_group_id
      end
    end

    def set_accounts
      return if @in_uid.blank?

      root_group_id = cur_root_group.id
      copy = self.accounts.to_a.reject do |e|
        e.group_id == root_group_id
      end
      copy << SS::User::Model::Account.new(uid: @in_uid.strip, group_id: root_group_id)

      self.accounts = copy
    end

  class << self
    public
      def allow(action, user, opts = {})
        return where({}) if Sys::User.allowed?(action, user)
        super
      end
  end
end
