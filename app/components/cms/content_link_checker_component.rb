class Cms::ContentLinkCheckerComponent < ApplicationComponent
  include ActiveModel::Model

  delegate :br, to: :helpers

  attr_accessor :cur_site, :cur_user, :checker

  def result_status(result)
    case result.result
    when :success
      "success"
    when :nofollow
      "nofollow"
    when :skip
      "skip"
    else
      "failure"
    end
  end

  def result_status_label(result)
    case result.result
    when :success
      tag.span t("errors.messages.link_check_success"), class: "status-label success"
    when :nofollow
      tag.span "[nofollow]", class: "status-label nofollow"
    when :skip
      tag.span "[skip]", class: "status-label skip"
    else
      tag.span t("errors.messages.link_check_failure"), class: "status-label failure"
    end
  end
end
