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

    @cur_node = Cms::Node.site(@cur_site).find(cid)
  end

  def set_search_params
    @s ||= begin
      s = SS::TempFileSearchParam.new(ss_mode: @ss_mode, cur_site: @cur_site, cur_user: @cur_user, cur_node: cur_node)
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
    @items ||= base_items.reorder(filename: 1).page(params[:page]).per(20)
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
        if params.key?(:file_view)
          file_view_options = params.require(:file_view).permit(
            :name, :show_properties, :show_attach, :show_delete, :show_copy_url)
          %i[show_properties show_attach show_delete show_copy_url].each do |boolean_prop|
            if file_view_options.key?(boolean_prop)
              file_view_options[boolean_prop] = !%w(0 false).include?(file_view_options[boolean_prop])
            end
          end
        else
          file_view_options = {}
        end
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
