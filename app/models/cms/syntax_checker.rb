module Cms::SyntaxChecker
  extend SS::RescueWith

  FULL_WIDTH_SPACE = '　'.freeze
  SP = " ".freeze
  HALF_AL_NUM_PAT = "A-Za-z0-9".freeze
  FULL_AL_NUM_PAT = "Ａ-Ｚａ-ｚ０-９".freeze
  AL_NUM_PAT = "#{HALF_AL_NUM_PAT}#{FULL_AL_NUM_PAT}".freeze
  AL_NUM_SP_PAT = "#{AL_NUM_PAT}#{SP}".freeze
  AL_NUM_REGEX = /[#{AL_NUM_PAT}]([#{AL_NUM_SP_PAT}]*[#{AL_NUM_PAT}])?/.freeze

  COLUMN_CHECKER_MAP = {
    value: Cms::SyntaxChecker::Column::ValueChecker,
    editor: Cms::SyntaxChecker::Column::EditorChecker,
    link: Cms::SyntaxChecker::Column::LinkChecker,
    list: Cms::SyntaxChecker::Column::ListChecker,
    table: Cms::SyntaxChecker::Column::TableChecker,
    presence: Cms::SyntaxChecker::Column::PresenceChecker,
  }.freeze

  COLUMN_CORRECTOR_MAP = {
    value: Cms::SyntaxChecker::Column::ValueCorrector,
    editor: Cms::SyntaxChecker::Column::EditorCorrector,
    link: Cms::SyntaxChecker::Column::LinkCorrector,
    list: Cms::SyntaxChecker::Column::ListCorrector,
    table: Cms::SyntaxChecker::Column::TableCorrector,
    # presence: Cms::SyntaxChecker::Column::PresenceCorrector,
  }.freeze

  Content = Data.define(:id, :name, :resolve, :content, :type, :column_value) do
    def self.from_hash(hash)
      new(
        id: hash[:id] || hash["id"],
        name: hash[:name] || hash["name"],
        resolve: hash[:resolve] || hash["resolve"],
        content: hash[:content] || hash["content"],
        type: hash[:type] || hash["type"])
    end

    def initialize(id:, name:, resolve:, content:, type:, **kwargs)
      super(
        id: id, name: name, resolve: resolve, content: content, type: type, column_value: kwargs[:column_value])
    end
  end
  CheckerError = Data.define(:context, :content, :code, :checker, :error, :corrector, :corrector_params) do
    def initialize(context:, content:, code:, checker:, error:, **kwargs)
      super(
        context: context, content: content, code: code, checker: checker, error: error,
        corrector: kwargs[:corrector], corrector_params: kwargs[:corrector_params])
    end

    def id
      content.try(:id)
    end

    def name
      content.try(:name)
    end

    def idx
      context.idx
    end

    def full_message
      error.is_a?(Symbol) ? I18n.t("errors.messages.#{error}", default: nil) : error
    end

    def detail
      if error.is_a?(Symbol)
        I18n.t("errors.messages.syntax_check_detail.#{error}", default: SS::EMPTY_ARRAY)
      else
        SS::EMPTY_ARRAY
      end
    end

    def to_compat_hash
      { id: id, idx: idx, code: code, msg: full_message, detail: detail,
        collector: corrector, collector_params: corrector_params }
    end
  end

  class CheckerFeature
    include ActiveModel::Model

    attr_accessor :context

    def unfavorable_word_set
      @unfavorable_word_set ||= begin
        set = Set.new

        Cms::UnfavorableWord.all.site(context.cur_site).and_enabled.pluck(:body).each do |body|
          body.split(/\R+/).each do |word|
            word = word.strip
            next if word.blank?

            set.add(word)
          end
        end

        set
      end
    end

    def include_unfavorable_word?(text)
      return false if text.blank?
      unfavorable_word_set.include?(text)
    end

    def link_text_min_length
      ret = context.cur_site.syntax_checker_link_text_min_length
      ret || Cms::SyntaxChecker::LinkTextSetting::DEFAULT_SYNTAX_CHECKER_LINK_TEXT_MIN_LENGTH
    end
  end

  CheckerContext = Data.define(
    :cur_site, :cur_user, :contents, :idx, :html, :fragment, :header_check, :h_level_check, :errors, :feature) do
    def initialize(cur_site:, cur_user:, contents:, **kwargs)
      super(
        cur_site: cur_site, cur_user: cur_user, contents: contents,
        idx: kwargs[:idx], html: kwargs[:html], fragment: kwargs[:fragment],
        header_check: kwargs.fetch(:header_check, false), h_level_check: kwargs.fetch(:h_level_check, 0),
        errors: kwargs.fetch(:errors, []), feature: CheckerFeature.new(context: self))
    end

    delegate :include_unfavorable_word?, :link_text_min_length, to: :feature
  end
  CorrectorContext = Struct.new(:cur_site, :cur_user, :content, :params, :result) do
    def set_result(ret)
      if content.type == "array"
        self.result = ret
      else
        self.result = ret[0]
      end
    end
  end
  CorrectorParam = Data.define(:id, :column_value_id, :corrector, :corrector_params) do
    def self.parse_params(encoded_params)
      decoded_params = Base64.urlsafe_decode64(encoded_params)
      json_params = JSON.parse(decoded_params)
      new(
        id: json_params['id'], column_value_id: json_params['column_value_id'],
        corrector: json_params['corrector'], corrector_params: json_params['corrector_params'])
    end

    def initialize(id:, corrector:, **option)
      super(id: id, column_value_id: option[:column_value_id], corrector: corrector, corrector_params: option[:corrector_params])
    end
  end
  CorrectorResult = Data.define(:content)

  module_function

  mattr_accessor :html_checkers, :text_checkers
  self.html_checkers = [
    # checkers for both html and text
    Cms::SyntaxChecker::DateFormatChecker,
    Cms::SyntaxChecker::InterwordSpaceChecker,
    Cms::SyntaxChecker::KanaCharacterChecker,
    Cms::SyntaxChecker::MultibyteCharacterChecker,
    Cms::SyntaxChecker::ReplaceWordsChecker,
    # checkers only for html
    Cms::SyntaxChecker::AdjacentAChecker,
    Cms::SyntaxChecker::AreaAltChecker,
    Cms::SyntaxChecker::EmbeddedMediaChecker,
    Cms::SyntaxChecker::IframeTitleChecker,
    Cms::SyntaxChecker::ImgAltChecker,
    Cms::SyntaxChecker::ImgDataUriSchemeChecker,
    Cms::SyntaxChecker::LinkTextChecker,
    Cms::SyntaxChecker::OrderOfHChecker,
    Cms::SyntaxChecker::TableChecker,
    Cms::SyntaxChecker::UrlSchemeChecker,
    Cms::SyntaxChecker::InternalLinkChecker
  ]
  self.text_checkers = [
    # checkers for both html and text
    Cms::SyntaxChecker::DateFormatChecker,
    Cms::SyntaxChecker::InterwordSpaceChecker,
    Cms::SyntaxChecker::KanaCharacterChecker,
    Cms::SyntaxChecker::MultibyteCharacterChecker,
    Cms::SyntaxChecker::ReplaceWordsChecker,
    Cms::SyntaxChecker::UnfavorableWordsChecker
  ]

  COLUMN_VALUE_SYNTAX_CHECKERS = %i[value editor link list table presence].freeze

  def check(cur_site:, cur_user:, contents:)
    context = Cms::SyntaxChecker::CheckerContext.new(
      cur_site: cur_site, cur_user: cur_user, contents: contents, idx: nil, html: nil, fragment: nil,
      header_check: false, h_level_check: 0, errors: [])

    contents.each do |content|
      if content.content.present?
        check_content(context, content)
        next
      end

      if content.column_value
        check_column_value(context, content)
      end
    end
    if contents.any? { _1.column_value.is_a?(Cms::Column::Value::Headline) }
      checker = Cms::SyntaxChecker::Column::OrderOfHChecker.new(context: context, contents: contents)
      checker.check
    end

    if context.errors.present?
      if cur_user && !cur_user.cms_role_permit_any?(cur_site, "edit_cms_ignore_syntax_check")
        error = Cms::SyntaxChecker::CheckerError.new(
          context: context, content: nil, code: nil, checker: nil,
          error: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
        context.errors.prepend(error)
      end
    end

    context
  end

  def check_page(cur_site:, cur_user:, page:, **_unused_options)
    contents = build_contents(page, cur_site: cur_site)
    context = check(cur_site: cur_site, cur_user: cur_user, contents: contents)
    context = sort_context_errors(context)
    context
  end

  def check_content(context, content)
    if content.resolve == "html"
      checkers = Cms::SyntaxChecker.html_checkers
    else
      checkers = Cms::SyntaxChecker.text_checkers
    end

    Cms::SyntaxChecker::Base.each_html_with_index(content) do |html, idx|
      fragment = Nokogiri::HTML5.fragment(html)
      checkers.each do |checker|
        rescue_with do
          innstance = checker.new
          innstance.check(context.with(idx: idx, html: html, fragment: fragment), content)
        end
      end
    end
  end

  def check_column_value(context, content)
    column_value = content.column_value
    column_value.fields.each do |attribute, field_def|
      metadata = field_def.options[:metadata]
      next if metadata.blank?

      syntax_check = metadata[:syntax_check]
      next if syntax_check.blank?

      syntax_check.each do |key, options|
        column_value_checker_class = COLUMN_CHECKER_MAP[key]
        unless column_value_checker_class
          Rails.logger.info { "Unknown checker: '#{key}'" }
          next
        end

        column_value_checker = column_value_checker_class.new(
          context: context, content: content, column_value: column_value, attribute: attribute, params: options)
        column_value_checker.check
      end
    end
  end

  def correct(cur_site:, cur_user:, content:, corrector:, params:)
    default_result = content.content
    context = Cms::SyntaxChecker::CorrectorContext.new(
      cur_site: cur_site, cur_user: cur_user, content: content, params: params, result: default_result)

    if content.resolve == "html"
      checkers = Cms::SyntaxChecker.html_checkers
    else
      checkers = Cms::SyntaxChecker.text_checkers
    end

    checker = checkers.find { |checker| checker.name == corrector }
    return context if !checker

    instance = checker.new
    instance.correct(context)

    context
  end

  def correct_page(cur_site:, cur_user:, page:, params:, **_unused_options)
    contents = build_contents(page, cur_site: cur_site)
    target_content = contents.find { _1.id == params.id }

    corrector_class = Cms::SyntaxChecker.html_checkers.find { |checker| checker.name == params.corrector }
    if target_content.column_value.present?
      column_value = target_content.column_value
      column_value.fields.each do |attribute, field_def|
        metadata = field_def.options[:metadata]
        next if metadata.blank?

        syntax_check = metadata[:syntax_check]
        next if syntax_check.blank?
        next unless COLUMN_VALUE_SYNTAX_CHECKERS.any? { syntax_check[_1] }

        syntax_check.each do |key, options|
          column_value_corrector_class = COLUMN_CORRECTOR_MAP[key]
          unless column_value_corrector_class
            Rails.logger.info { "Unknown corrector: '#{key}'" } if key != :presence
            next
          end

          column_value_corrector = column_value_corrector_class.new(
            cur_site: cur_site, cur_user: cur_user, page: page, column_value: column_value, attribute: attribute,
            corrector_class: corrector_class, corrector_params: params.corrector_params,
            params: options
          )
          column_value_corrector.correct
        end
      end

      result = CorrectorResult.new(content: target_content)
    else
      corrector = corrector_class.new
      corrected_value = corrector.correct2(page.html, params: params.corrector_params)
      page.html = corrected_value

      result = CorrectorResult.new(content: target_content.with(content: corrected_value))
    end

    result
  end

  def build_contents(content, cur_site:)
    if form_page?(content)
      content.column_values.reorder(order: :asc).map do |column_value|
        Content.new(
          id: "column-value-#{column_value.id}",
          name: column_value.name.presence || column_value.column.try(:name).presence || "column-value-#{column_value.id}",
          resolve: "html", content: nil, type: "string", column_value: column_value
        )
      end
    elsif content.is_a?(Cms::Addon::Body) || content.is_a?(Cms::Addon::Html) || content.is_a?(Cms::Addon::LayoutHtml)
      [
        Content.new(
          id: "item_html", name: content.class.t(:html),
          resolve: "html", content: content.html, type: "string")
      ]
    else
      raise "unknown content"
    end
  end

  def form_page?(content)
    content.respond_to?(:form) && content.form.present?
  end

  def sort_context_errors(context)
    context.errors.sort! do |lhs, rhs|
      next -1 if lhs.id.nil?
      next 1 if rhs.id.nil?

      lhs_order = lhs.content.column_value.try(:order) || 0
      rhs_order = rhs.content.column_value.try(:order) || 0

      lhs_order <=> rhs_order
    end
    context
  end
end
