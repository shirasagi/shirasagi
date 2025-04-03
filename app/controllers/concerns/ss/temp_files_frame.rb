module SS::TempFilesFrame
  extend ActiveSupport::Concern

  included do
    model SS::File

    layout 'ss/item_frame'

    before_action :set_search_params

    helper_method :cur_node, :items
  end

  private

  def cur_node
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

    cur_node = Cms::Node.site(@cur_site).find(cid)
    raise "404" unless cur_node.allowed?(:read, @cur_user, site: @cur_site)

    @cur_node = cur_node
  end

  def setting
    @setting ||= SS::TempFileFrameSetting.decode(params[:setting])
  end

  def set_search_params
    @s ||= begin
      s = SS::TempFileSearchParam.new(
        ss_mode: @ss_mode, cur_site: @cur_site, cur_user: @cur_user, cur_node: cur_node, accepts: setting.accepts)
      if params.key?(:s)
        s.attributes = params[:s].permit(s.class.permitted_fields)
      end
      s.set_default
      s.validate
      s
    end
  end

  def base_items
    set_search_params
    @base_items ||= @s.query(SS::File, SS::File.unscoped)
  end

  def items
    @items ||= base_items.reorder(filename: 1).page(params[:page]).per(SS.max_files_per_page)
  end

  def crud_redirect_url
    url_for(action: :index, cid: cur_node, s: params[:s].try(:to_unsafe_h))
  end

  def set_item
    @item ||= begin
      item = SS::File.find(params[:id])
      item = item.becomes_with_model
      item = becomes_to_temp_file(item)
      @model = item.class
      item
    end
  end

  def becomes_to_temp_file(item)
    return item if @ss_mode != :cms
    return item if !item.is_a?(SS::TempFile)

    item.becomes_with(Cms::TempFile)
  end

  def needs_copy?(item)
    !item.is_a?(SS::TempFile) && !item.is_a?(Cms::TempFile)
  end

  public

  def index
    render
  end

  def select
    set_item
    if needs_copy?(@item)
      @item = @item.copy(cur_user: @cur_user)
    end

    respond_to do |format|
      format.html do
        file_view_options = {}
        file_view_options[:name] = setting.field_name if setting.field_name.present?
        file_view_options[:show_properties] = setting.show_properties if setting.show_properties.present?
        file_view_options[:show_attach] = setting.show_attach if setting.show_attach.present?
        file_view_options[:show_delete] = setting.show_delete if setting.show_delete.present?
        file_view_options[:show_copy_url] = setting.show_copy_url if setting.show_copy_url.present?
        file_view_options[:show_opendata] = setting.show_opendata if setting.show_opendata.present?

        component = SS::FileViewV2Component.new(cur_user: @cur_user, file: @item, **file_view_options)
        component.animated = "animate__animated animate__bounceIn"
        render component, layout: false
      end
      format.json do
        json_data = @item.as_json({ methods: %i[humanized_name image? basename extname url thumb_url] })
        json_data["sanitizer_state"] = sanitizer_state = @item.try(:sanitizer_state) || 'none'
        json_data["sanitizer_state_label"] = SS::UploadPolicy.sanitizer_state_label(sanitizer_state)
        render json: json_data, status: :created, content_type: json_content_type
      end
    end
  end
end
