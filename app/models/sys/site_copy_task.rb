class Sys::SiteCopyTask
  include SS::Model::Task
  include Sys::Permission

  set_permission_name "sys_sites", :edit

  default_scope ->{ where(name: "sys::site_copy") }

  attr_accessor :target_host_domains_with_subdir

  # field :results, type: Hash
  field :target_host_name, type: String
  field :target_host_host, type: String
  field :target_host_domains, type: SS::Extensions::Words
  field :target_host_subdir, type: String
  belongs_to :target_host_parent, class_name: "SS::Site"
  belongs_to :source_site, class_name: "SS::Site"
  field :copy_contents, type: SS::Extensions::Words

  permit_params :target_host_name, :target_host_host, :target_host_domains, :target_host_subdir,
    :target_host_parent_id, :source_site_id, copy_contents: []

  validates :target_host_name, presence: true, length: { maximum: 40 }
  validates :target_host_host, presence: true, length: { minimum: 3, maximum: 16 }
  validate :validate_target_host_host, if: ->{ target_host_host.present? }
  validates :target_host_domains, presence: true, domain: true
  validates :target_host_subdir, presence: true, if: ->{ target_host_parent.present? }
  validates :target_host_parent_id, presence: true, if: ->{ target_host_subdir.present? }
  validate :validate_target_host_domains, if: ->{ target_host_domains.present? }
  validates :source_site_id, presence: true

  def clear_params
    self.target_host_name = nil
    self.target_host_host = nil
    self.target_host_domains = nil
    self.target_host_subdir = nil
    self.target_host_parent_id = nil
    self.source_site_id = nil
    self.copy_contents = nil
  end

  private

  def validate_target_host_host
    return if target_host_host.blank?
    return if closed.present?
    errors.add :target_host_host, :duplicate if SS::Site.ne(id: id).where(host: target_host_host).exists?
  end

  def validate_target_host_domains
    return if closed.present?

    self.target_host_domains = target_host_domains.uniq
    self.target_host_domains_with_subdir = []
    target_host_domains.each do |domain|
      self.target_host_domains_with_subdir << (target_host_subdir.present? ? "#{domain}/#{target_host_subdir}" : domain)
    end

    if SS::Site.ne(id: id).any_in(domains_with_subdir: target_host_domains_with_subdir).exists?
      errors.add :target_host_domains_with_subdir, :duplicate
    end
  end
end
