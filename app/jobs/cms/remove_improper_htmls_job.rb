class Cms::RemoveImproperHtmlsJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
    puts message
  end

  def put_error(message)
    Rails.logger.info(message)
    puts message
    @errors << message
  end

  def dry_run?
    @dry_run.present?
  end

  def ignore_path?(path)
    @ignore_paths ||= SS.config.remove_improper_htmls.ignore_paths
    path = path.delete_prefix(site.root_path + "/")
    @ignore_paths.find { |ignore_path| path == ignore_path || path.start_with?(ignore_path + "/") }.present?
  end

  def perform(opts = {})
    @dry_run = opts[:dry_run].presence
    @email = opts[:email].presence
    put_log("\# #{site.name}")

    @errors = []
    public_html_paths(site) do |path|
      if ignore_path?(path)
        put_error("skip #{path}")
        next
      end

      cur_main_path = format_cur_paths(path)
      if check_as_page(cur_main_path) || check_as_node(cur_main_path)
        next
      end

      put_error("remove #{path}")
      ::Fs.rm_rf(path) if !dry_run?
    end

    send_error_mail if @email.present?
  end

  def public_html_paths(site)
    dir = site.path
    child_dirs = site.children.map(&:path)

    ::Dir.glob("#{dir}/**/*.html") do |path|
      next if child_dirs.find { |child_dir| (path == child_dir) || path.start_with?(child_dir + "/") }
      yield(path)
    end
  end

  def format_cur_paths(path)
    @cur_path = path.delete_prefix(site.root_path)
    @cur_main_path = path.delete_prefix(site.path)
    if @cur_path.match?(/\.p[1-9]\d*\.html$/)
      @cur_path.sub!(/\.p\d+\.html$/, ".html")
      @cur_main_path.sub!(/\.p\d+\.html$/, ".html")
    end
    @cur_main_path
  end

  def page_controller
    @page_controller ||= begin
      cont = Cms::Agents::Tasks::PagesController.new
      cont.instance_variable_set(:@cur_site, site)
      cont.instance_variable_set(:@preview, false)
      cont
    end
  end

  def node_controller
    @node_controller ||= begin
      cont = Cms::Agents::Tasks::NodesController.new
      cont.instance_variable_set(:@cur_site, site)
      cont.instance_variable_set(:@preview, false)
      cont
    end
  end

  def check_as_page(path)
    controller = page_controller
    page = controller.find_page(path)

    return false unless page
    return false unless page.send(:serve_static_file?)
    return false unless page.public?
    return false unless page.public_node?

    spec = controller.recognize_page(page)
    return false unless spec

    true
  end

  def check_as_node(path)
    controller = node_controller
    node = controller.find_node(path)

    return false unless node
    return false unless node.send(:serve_static_file?)
    return false unless node.public?
    return false unless node.public?
    return false unless node.public_node?

    spec = controller.recognize_node(node, path)
    return false unless spec

    true
  end

  def send_error_mail
    body = "[#{@errors.size} errors]\n" + @errors.join("\n")
    ActionMailer::Base.mail(
      from: "shirasagi@" + site.domain.sub(/:.*/, ""),
      to: @email,
      subject: "[#{site.name}] Remove Improper Htmls: #{@errors.size} errors",
      body: body
    ).deliver_now
  end
end
