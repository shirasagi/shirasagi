class Cms::Page::MoveService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :cur_node, :source, :destination, :task

  validate :validate_destination

  def move
    raise "400" if source.respond_to?(:branch?) && source.branch?
    return false if invalid?

    permission_options = { site: cur_site }
    permission_options[:node] = cur_node if cur_node
    raise "403" unless source.allowed?(:move, cur_user, **permission_options)

    source.cur_site = cur_site
    source.cur_user = cur_user

    if task
      task.log "# #{I18n.t("ss.buttons.move")}"
      task.log "#{source.filename}(#{source.id})"
    end

    result = source.move(destination)

    if task
      if result
        task.log "moved to #{destination}"
      else
        task.log "failed\n#{source.errors.full_messages.join("\n")}"
      end
    end

    unless result
      SS::Model.copy_errors(source, self)
    end

    result
  end

  # 一括移動用：結果をハッシュ形式で返す
  def move_page(page, destination_filename)
    self.source = page
    self.destination = destination_filename

    result = move

    {
      success: result,
      errors: result ? [] : errors.full_messages,
      page_id: page.id,
      filename: page.filename,
      destination_filename: destination_filename
    }
  rescue => e
    {
      success: false,
      errors: [e.message],
      page_id: page.id,
      filename: page.filename,
      destination_filename: destination_filename
    }
  end

  private

  def validate_destination
    if destination.blank?
      errors.add :destination, :blank
      return
    end

    return unless source

    source.validate_destination_filename(destination)
    source.errors.each do |error|
      errors.add :destination, error.message
    end
  end
end
