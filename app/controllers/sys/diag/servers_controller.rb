class Sys::Diag::ServersController < ApplicationController
  include Sys::BaseFilter

  skip_before_action :verify_authenticity_token, only: :show

  PROC_CPUINFO_FILE_PATH = "/proc/cpuinfo".freeze
  PROC_MEMINFO_FILE_PATH = "/proc/meminfo".freeze

  navi_view "sys/diag/main/navi"
  menu_view nil

  helper_method :uptime
  helper_method :http_key?, :rack_key?, :rails_key?, :other_key?

  private

  def set_crumbs
    @crumbs << ["Server Info", action: :show]
  end

  def uptime
    ret = nil
    r, w = ::IO.pipe
    begin
      pid = spawn(%w(uptime uptime), out: w)
      w.close
      _, status = ::Process.waitpid2(pid)
      ret = r.read if status.success?
    rescue => e
      Rails.logger.debug("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    ensure
      r.close if r.closed?
      w.close if w.closed?
    end

    ret
  end

  def http_key?(key)
    /^[A-Z_]+$/.match?(key)
  end

  def rack_key?(key)
    key.start_with?("rack.")
  end

  def rails_key?(key)
    key.start_with?("action_dispatch.", "action_controller.")
  end

  def other_key?(key)
    return false if http_key?(key)
    return false if rack_key?(key)
    return false if rails_key?(key)

    true
  end

  public

  def show
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end
end
