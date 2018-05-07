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

  def commands_path
    SS.config.cms.commands_path.collect do |path|
      [Rails.root, path].join('/')
    end
  end

  def escaped_command
    input = command.split("\s")
    input[0] = input[0].slice(/[^\/]*$/)
    input.join(' ').strip
  end

  def run(target, path)
    data = []
    data << "PATH=#{commands_path.join(':') rescue nil}"
    data << [escaped_command, target, path].join(' ')
    self.output = Open3.capture2e(data.join(';'))[0]
    self.update
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
  end
end
