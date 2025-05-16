# frozen_string_literal: true

class Cms::SyntaxCheckDetailBoxComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :syntax_checker

  def initialize(syntax_checker:)
    super()
    @syntax_checker = syntax_checker
  end

  def render?
    syntax_checker&.errors.present?
  end

  def call
    tag.div(id: "errorSyntaxChecker", class: "errorExplanation") do
      safe_join([
        tag.h2(t("cms.syntax_check")),
        render_error_explanation
      ])
    end
  end

  private

  def render_error_explanation
    tag.div(class: "errorExplanationBody") do
      safe_join([
        tag.p(t("errors.template.body")),
        render_error_list
      ])
    end
  end

  def render_error_list
    tag.ul do
      safe_join(
        syntax_checker.errors.each_with_index.map { |error, idx| render_error_detail(error, idx) }
      )
    end
  end

  def render_error_detail(error, idx = nil)
    safe_join([
      render_column_name(error),
      render_error_code(error),
      render_error_message(error, idx)
    ].compact)
  end

  def render_column_name(error)
    return unless error[:id].present?
    tag.li(error[:id], class: "column-name")
  end

  def render_error_code(error)
    return unless error[:code].present?
    tag.li(class: "code") do
      tag.code(error[:code].to_s)
    end
  end

  def render_error_message(error, idx = nil)
    return unless error[:msg].present?
    tag.ul do
      tag.li do
        tag.span(class: "message detail") do
          safe_join([
            error[:msg].to_s,
            error[:detail].present? ? render_tooltip(error[:detail]) : nil,
            render_auto_correct_button(error, idx)
          ].compact)
        end
      end
    end
  end

  def render_tooltip(detail)
    return unless detail.present?
    tag.div(class: "tooltip") do
      "!".html_safe +
        tag.ul(class: "tooltip-content") do
          safe_join(Array(detail).map { |d| tag.li(d.to_s) })
        end
    end
  end

  def render_auto_correct_button(error, idx = nil)
    return unless error[:collector].present?
    tag.button(I18n.t("cms.auto_correct.link"),
      type: "submit",
      class: "btn btn-auto-correct",
      name: "auto_correct",
      value: idx
    )
  end
end
