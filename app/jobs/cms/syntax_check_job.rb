class Cms::SyntaxCheckJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  THRESHOLD = 10.seconds

  self.task_class = Cms::Task
  self.task_name = "cms:syntax_check"

  def perform(*args)
    options = args.extract_options!
    @force = options.fetch(:force, false)
    each_page do |page|
      if syntax_check_result_old?(page)
        update_syntax_check_result(page)
      end
    end
  end

  private

  def now
    @now ||= Time.zone.now
  end

  def each_page
    criteria = Cms::Page.all.site(site)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        Rails.logger.tagged("#{page.filename}(#{page.id})") do
          yield page
        end
      end
    end
  end

  def syntax_check_result_old?(page)
    return true if @force
    return true if page.syntax_check_result_checked.blank?

    # Form_Alert で非同期にアクセシビリティチェックを実施。このタイミングで結果が保存される。
    # アクセシビリティチェックに成功するか、アクセシビリティ違反を無視すれば保存される。
    # 先にアクセシビリティチェックを実施、次に保存という処理の流れとなる。
    #
    # そこで、ページの更新日時とアクセシビリティチェック実施日時の差が十分に小さければ、
    # アクセシビリティチェック結果が十分に信頼できると見なすことにする。
    # 十分に信頼できる場合、処理効率の観点からアクセシビリティチェック結果を更新しない。
    return false if page.syntax_check_result_checked >= page.updated

    diff = page.updated.to_f - page.syntax_check_result_checked.to_f
    diff > THRESHOLD
  end

  def update_syntax_check_result(page)
    syntax_checker_context = Cms::SyntaxChecker.check_page(
      cur_site: site, cur_user: user, page: page)
    page.set_syntax_check_result(syntax_checker_context)

    Rails.logger.info { "アクセシビリティチェック結果を更新しました。" }
  end
end
