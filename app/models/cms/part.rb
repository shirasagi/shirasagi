class Cms::Part
  include Cms::Model::Part
  include SS::PluginRepository

  index({ site_id: 1, filename: 1 }, { unique: true })

  plugin_type "part"

  class Base
    include Cms::Model::Part

    default_scope ->{ where(route: /^cms\//) }
  end

  class Free
    include Cms::Model::Part
    include Cms::Addon::Html
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::SyntaxCheckable

    default_scope ->{ where(route: "cms/free") }

    before_validation :syntax_check, if: -> { html.present? && html_changed? }

    private

    def syntax_check
      Rails.logger.debug("[Cms::Part::Free#syntax_check] 開始")
      Rails.logger.debug("[Cms::Part::Free#syntax_check] html: #{html.inspect}")
      Rails.logger.debug("[Cms::Part::Free#syntax_check] site: #{try(:site).inspect}")
      Rails.logger.debug("[Cms::Part::Free#syntax_check] user: #{try(:user).inspect}")

      contents = [{ "id" => "html", "content" => html, "resolve" => "html", "type" => "scalar" }]
      Rails.logger.debug("[Cms::Part::Free#syntax_check] contents: #{contents.inspect}")

      @syntax_checker = Cms::SyntaxChecker.check(cur_site: try(:site), cur_user: try(:user), contents: contents)
      Rails.logger.debug("[Cms::Part::Free#syntax_check] syntax_checker: #{@syntax_checker.inspect}")

      if @syntax_checker.errors.present?
        Rails.logger.debug("[Cms::Part::Free#syntax_check] エラー検出: #{@syntax_checker.errors.inspect}")
        @syntax_checker.errors.each do |error|
          errors.add :base, error[:msg]
        end
        Rails.logger.debug("[Cms::Part::Free#syntax_check] エラー追加後のerrors: #{errors.full_messages.inspect}")
        return false
      end

      Rails.logger.debug("[Cms::Part::Free#syntax_check] 正常終了")
      true
    end
  end

  class Node
    include Cms::Model::Part
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/node") }
  end

  class Node2
    include Cms::Model::Part
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    self.use_conditions = false
    self.use_node_routes = true

    default_scope ->{ where(route: "cms/node2") }
  end

  class Page
    include Cms::Model::Part
    include Event::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/page") }
  end

  class Tabs
    include Cms::Model::Part
    include Cms::Addon::Tabs
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/tabs") }
  end

  class Crumb
    include Cms::Model::Part
    include Cms::Addon::Crumb
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/crumb") }
  end

  class SnsShare
    include Cms::Model::Part
    include Cms::Addon::SnsShare
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/sns_share") }
  end

  class CalendarNav
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/calendar_nav") }
  end

  class MonthlyNav
    include Cms::Model::Part
    include Cms::Addon::MonthlyNav
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/monthly_nav") }
  end

  class SiteSearchKeyword
    include Cms::Model::Part
    include Cms::Addon::SiteSearch::Keyword
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/site_search_keyword") }
  end

  class SiteSearchHistory
    include Cms::Model::Part
    include Cms::Addon::SiteSearch::History
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/site_search_history") }
  end

  class HistoryList
    include ::Cms::Model::Part
    include ::Cms::Addon::HistoryList
    include ::Cms::Addon::Release
    include ::Cms::Addon::GroupPermission
    include ::History::Addon::Backup

    default_scope ->{ where(route: "cms/history_list") }
  end

  class Print
    include Cms::Model::Part
    include Cms::Addon::Print
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/print") }
  end

  class ClipboardCopy
    include ::Cms::Model::Part
    include ::Cms::Addon::ClipboardCopy
    include ::Cms::Addon::Release
    include ::Cms::Addon::GroupPermission
    include ::History::Addon::Backup

    default_scope ->{ where(route: "cms/clipboard_copy") }
  end
end
