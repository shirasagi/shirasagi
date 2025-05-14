class SS::RemoveSiteJob < SS::ApplicationJob
  # 1. cms_pages, cms_parts, cms_layouts, cms_nodes, ss_files の順に削除する
  # 2. 残りを MODULES_BOUND_TO_SITE より削除する
  # 3. 最後に site と public 配下のファイルを削除する
  def perform(site_id)
    @site = SS::Site.find(site_id)

    ## basic contents
    models = [::Cms::Page, ::Cms::Part, ::Cms::Layout, ::Cms::Node]
    remove_all(models)

    ## ss_files
    models = [::SS::File]
    remove_all(models)

    ## other contents
    models = ::Cms::MODULES_BOUND_TO_SITE.map(&:constantize)
    models = models.select { |model| removable_bound_to_site?(model) }
    remove_all(models)

    ## public files
    put_log("remove #{@site.name}")
    ::Fs.rm_rf @site.path
    @site.destroy
  end

  def remove_all(models)
    models.each do |model|
      put_log("remove #{model}")
      ids = model.where(site_id: @site.id).pluck(:id)
      ids.each do |id|
        item = model.find(id) rescue nil
        next if item.nil?
        def item.create_history_trash; end
        item.destroy
      end
    end
  end

  def removable_bound_to_site?(model)
    return false if model.include?(::Cms::Content)
    return false if model.include?(::SS::Model::File)
    return false if model.include?(::SS::Model::JobLog)
    model.include?(::SS::Reference::Site) || model.include?(::Cms::Reference::Site)
  end

  def put_log(message)
    puts message
    Rails.logger.info(message)
  end
end
