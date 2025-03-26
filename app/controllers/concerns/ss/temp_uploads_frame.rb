module SS::TempUploadsFrame
  extend ActiveSupport::Concern

  included do
    model SS::File

    layout 'ss/item_frame'

    helper_method :cur_node, :accepts
  end

  private

  def set_node
    return @cur_node if instance_variable_defined?(:@cur_node)

    if @ss_mode != :cms
      @cur_node = nil
      return @cur_node
    end
    cid = params[:cid].to_s
    if cid.blank? || cid == "-"
      @cur_node = nil
      return @cur_node
    end

    @cur_node = Cms::Node.site(@cur_site).find(cid)
  end
  alias cur_node set_node

  def setting
    @setting ||= SS::TempFileFrameSetting.decode(params[:setting])
  end

  delegate :accepts, to: :setting

  public

  def index
    render
  end

  def preview
    files = params.require(:item).permit(files: %i[name size content_type])[:files]
    previews = []
    files.each do |file|
      preview = SS::TempFilePreview.new(cur_site: @cur_site, cur_user: @cur_user)
      preview.attributes = file
      if setting.accepts.present?
        preview.accepts = setting.accepts
      end
      preview.validate
      previews.push(preview)
    end

    render json: previews.map(&:to_h)
  end

  def create
    item_validator = SS::TempFileCreator.new(
      ss_mode: @ss_mode, cur_site: @cur_site, cur_user: @cur_user, cur_node: cur_node)
    if setting.accepts.present?
      item_validator.accepts = setting.accepts
    end

    item_validator.attributes = params.require(:item).permit(
      :name, :resizing, :quality, :image_resizes_disabled, :in_file)
    if item_validator.invalid?
      json_data = item_validator.errors.full_messages
      render json: json_data, status: :unprocessable_entity, content_type: json_content_type
      return
    end

    result = item_validator.save
    unless result
      json_data = item_validator.errors.full_messages
      render json: json_data, status: :unprocessable_entity, content_type: json_content_type
      return
    end

    json_data = item_validator.work_item.as_json({ methods: %i[humanized_name image? basename extname url thumb_url] })
    json_data[:sanitizer_state] = sanitizer_state = item_validator.work_item.try(:sanitizer_state) || 'none'
    json_data[:sanitizer_state_label] = SS::UploadPolicy.sanitizer_state_label(sanitizer_state)
    render json: json_data, status: :created, content_type: json_content_type
  end
end
