class Inquiry2::Column
  include SS::Document
  include SS::Reference::Site
  include SS::PluginRepository

  plugin_type 'column'

  def self.plugin(path)
    super
    type = path.sub('/', '/column/')
    type = type.classify
    model = type.constantize
    model.value_type
  end

  def self.route_options
    plugins.select { |plugin| plugin.enabled? }.map { |plugin| [plugin.name, plugin.path] }
  end

  ##
  # include SS::Document
  # include SS::Reference::Site
  # include Cms::SitePermission
  # include Inquiry2::Addon::InputSetting
  # include Cms::Addon::GroupPermission

  # seqid :id
  # field :state, type: String, default: "public"
  # field :max_upload_file_size, type: Integer, default: 0, overwrite: true
  # permit_params :id, :node_id, :state, :name, :html, :order, :max_upload_file_size
  # validates :state, :max_upload_file_size, presence: true

  # def answer_data(opts = {})
  #   answers = node.answers
  #   answers = answers.site(opts[:site]) if opts[:site].present?
  #   answers = answers.allow(:read, opts[:user]) if opts[:user].present?
  #   answers.search(opts).
  #     map { |ans| ans.data.entries.select { |data| data.column_id == id } }.flatten
  # end

  # def state_options
  #   [
  #     [I18n.t('ss.options.state.public'), 'public'],
  #     [I18n.t('ss.options.state.closed'), 'closed'],
  #   ]
  # end

  # def validate_upload_file(answer, data)
  #   # MegaBytes >> Bytes
  #   if self.max_upload_file_size.to_i > 0
  #     file_size  = data.values[3].to_i
  #     limit_size = (self.max_upload_file_size * 1024 * 1024).to_i

  #     if data.present? && data.value.present?
  #       if file_size > limit_size
  #         answer.errors.add :base, "#{name}#{I18n.t(
  #           "errors.messages.too_large_file",
  #           filename: data.values[1],
  #           size: ApplicationController.helpers.number_to_human_size(file_size),
  #           limit: ApplicationController.helpers.number_to_human_size(limit_size))}"
  #       end
  #     end
  #   end
  # end
end
