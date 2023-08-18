module History::LogFilter::View
  extend ActiveSupport::Concern

  def index
    set_options
    @s = OpenStruct.new params[:s]
    @s[:ref_coll] ||= 'all'
    @items = @model.where(cond).search(@s)
               .order_by(created: -1)
               .page(params[:page])
               .per(50)
  end

  def set_options
    ref_coll_options = [Cms::Node, Cms::Page, Cms::Part, Cms::Layout, SS::File].collect do |model|
      [model.model_name.human, model.collection_name]
    end
    search_opts = [[t('ss.operation'), 'action'], [t('ss.function'), 'controller']]
    search_opts += ref_coll_options if params[:controller] == "history/cms/logs"

    @operation_target_opts = search_opts.unshift([I18n.t('ss.all'), 'all'])
    @operator_target_opts = [[t("mongoid.models.ss/user"), 'user'], [t("mongoid.models.ss/group"), 'group']]

    criterias = @model.where(cond).order_by(created: -1).page(params[:page]).per(50)
    @action_opts = @model.where(cond).pluck(:action).uniq.map { |action| "#{action} #{action}".split }
    @controller_opts = @model.where(cond).pluck(:controller).uniq.map do |controller|
      "#{controller} #{controller}".split
    end

    @user_opts = @model.where(cond).pluck(:user_id).uniq.map do |user_id|
      user = Cms::User.find(user_id) rescue nil
      next if user.nil?

      "#{user.name},#{user.name}".split(",")
    end
    @user_opts.compact!

    groups = []
    @model.where(cond).pluck(:group_ids).compact.uniq.each do |group_ids|
      group_ids.each do |group_id|
        group = Cms::Group.find(group_id) rescue nil
        next if group.nil?

        groups << "#{group.name} #{group.name}".split
      end
      groups
    end
    @group_opts = groups.flatten(1).uniq.compact
  end

  def delete
    @item = History::DeleteParam.new
    @item.delete_term = '1.month'
  end

  def destroy
    item = History::DeleteParam.new params.require(:item).permit(:delete_term)
    if item.invalid?
      render
      return
    end

    num = @model.where(cond).lt(created: item.delete_term_in_time).destroy_all

    coll = @model.collection
    coll.client.command({ compact: coll.name })

    render_destroy num
  end

  def download
    @item = History::DownloadParam.new
    @item.save_term = '1.day'
    return if request.get? || request.head?

    @item.attributes = params.require(:item).permit(:encoding, :save_term, user_ids: [])
    if @item.invalid?
      render
      return
    end

    items = @model.where(cond)
    items = items.in(user: @item.user_ids) if @item.user_ids.present? && @item.user_ids.any?(&:present?)
    @item.save_term_in_time.try do |from|
      items = items.gte(created: from)
    end
    items = items.reorder(created: 1)

    enumerable = items.enum_csv(cur_site: @cur_site, encoding: @item.encoding)
    filename = "history_logs_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  private

  def render_destroy(result, opts = {})
    location = opts[:location].presence || { action: :index }

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: t("ss.notice.deleted") }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render template: "delete" }
        format.json { render json: :error, status: :unprocessable_entity }
      end
    end
  end
end
