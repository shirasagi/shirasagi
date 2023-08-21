class Sys::Diag::AppLogsController < ApplicationController
  include Sys::BaseFilter

  navi_view "sys/diag/main/navi"
  menu_view nil

  helper_method :relative_log_file_path, :tail_log

  private

  def log_file_path
    @log_file_path ||= Rails.application.config.paths["log"].first
  end

  def relative_log_file_path
    @relative_log_file_path ||= begin
      paths = []
      Rails.application.config.paths["log"].each { |path| paths << path }
      paths.first
    end
  end

  def tail_log
    return unless ::File.exist?(log_file_path)
    ::Fs.tail_lines(log_file_path)
  end

  def set_crumbs
    @crumbs << [ relative_log_file_path, url_for(action: :show) ]
  end

  public

  def show
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end
end
