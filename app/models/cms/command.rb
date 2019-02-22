class Cms::Command
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_commands"

  seqid :id
  field :name, type: String
  field :description, type: String
  field :order, type: Integer
  field :command, type: String
  field :output, type: String
  permit_params :name, :description, :order, :command
  validates :name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 400 }
  validates :command, presence: true

  default_scope -> { order_by(order: 1, name: 1) }

  def command_enabled?
    return false if SS.config.cms.command.blank?
    SS.config.cms.command['disable'].blank?
  end

  def commands_path
    SS.config.cms.command['path'].to_a.collect do |path|
      [Rails.root, path].join('/')
    end
  end

  def escaped_command(target, path)
    Shellwords.join([Shellwords.escape(command), target, path])
  end

  def run(target, path)
    env = { 'PATH' => commands_path.join(':') }
    data = Shellwords.join(['/bin/bash', '-rc', escaped_command(target, path)])
    self.output = Open3.capture2e(env, data, {})[0]
    self.update
  end

  def allowed?(action, user, opts = {})
    return false unless command_enabled?
    super
  end

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :html
      end
      criteria
    end

    def allow(action, user, opts = {})
      return false unless self.new.command_enabled?
      super
    end
  end
end
