class Cms::BodyCheckerComponent < ApplicationComponent
  include ActiveModel::Model
  include Cms::NodeHelper

  attr_accessor :cur_site, :cur_user, :cur_node, :item, :limits, :syntax_check_context
  attr_writer :check_content_path, :correct_content_path

  def check_content_path
    return @check_content_path if instance_variable_defined?(:@check_content_path)
    @check_content_path = url_for(action: :check_content) rescue nil
  end

  def correct_content_path
    return @correct_content_path if instance_variable_defined?(:@correct_content_path)
    @correct_content_path = url_for(action: :correct_content) rescue nil
  end

  def checkers
    @checkers ||= %i[syntax mobile_size link].select { send("#{_1}_available?") }
  end

  def render?
    check_content_path && correct_content_path && checkers.present?
  end

  private

  def syntax_available?
    return false if limits && !limits.include?(:syntax)
    cms_syntax_check_enabled?
  end

  def mobile_size_available?
    return false if limits && !limits.include?(:mobile_size)
    cur_site.mobile_enabled?
  end

  def link_available?
    return false if limits && !limits.include?(:link)
    !SS::Lgwan.enabled? || SS::Lgwan.web?
  end
end
