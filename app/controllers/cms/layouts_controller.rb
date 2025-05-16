class Cms::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  helper Cms::LayoutsHelper

  model Cms::Layout

  navi_view "cms/main/navi"

  before_action :set_tree_navi, only: [:index]

  private

  def set_crumbs
    @crumbs << [t("cms.layout"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
  end

  def syntax_check
    contents = [{ "id" => "html", "content" => @item.html, "resolve" => "html", "type" => "scalar" }]
    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)
    if @syntax_checker.errors.present?
      @syntax_checker.errors.each do |error|
        @item.errors.add :base, error[:msg]
      end
      return false
    end
    true
  end

  def auto_correct
    error_index = params[:auto_correct].to_i
    @item.errors.clear

    # 構文チェックを実行
    contents = [{ "id" => "html", "content" => @item.html, "resolve" => "html", "type" => "scalar" }]
    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    before_html = @item.html
    @syntax_checker.errors.each_with_index do |error, idx|
      next unless idx == error_index
      next unless error[:collector].present?

      Rails.logger.debug("[auto_correct] 修正前HTML: #{before_html.inspect}")

      case error[:collector]
      when "Cms::SyntaxChecker::InterwordSpaceChecker"
        content_html = error[:code]
      else
        content_html = @item.html
      end

      corrected = Cms::SyntaxChecker.correct(
        cur_site: @cur_site,
        cur_user: @cur_user,
        content: {
          "content" => content_html,
          "resolve" => "html",
          "type" => "scalar"
        },
        collector: error[:collector],
        params: (error[:collector_params] || {}).transform_keys(&:to_s)
      )

      next unless corrected.respond_to?(:result)
      corrected_html = corrected.result

      Rails.logger.debug("[auto_correct] 修正後HTML: #{corrected_html.inspect}")

      case error[:collector]
      when "Cms::SyntaxChecker::InterwordSpaceChecker"
        @item.html = replace_html(before_html, error[:code], corrected_html)
      else
        @item.html = corrected_html
      end
    end
  end

  def replace_html(before_html, error_code, corrected_html)
    pattern = Regexp.new(Regexp.escape(error_code))
    replaced_text = before_html.gsub(/#{pattern}/, corrected_html)
    replaced_text
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @node_target_options = @model.new.node_target_options

    @items = @model.site(@cur_site).
      node(@cur_node, params.dig(:s, :target)).
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end

  def create
    raise "403" unless @model.allowed?(:create, @cur_user, site: @cur_site, node: @cur_node)
    @item = @model.new get_params
    if params.key?(:auto_correct)
      auto_correct
      result = syntax_check
      render_create result
      return
    end
    render_create @item.valid? && syntax_check && @item.save
  end

  def update
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params
    if params.key?(:auto_correct)
      auto_correct
      result = syntax_check
      render_update result
      return
    else
      render_update @item.valid? && syntax_check && @item.save
    end
  end
end
