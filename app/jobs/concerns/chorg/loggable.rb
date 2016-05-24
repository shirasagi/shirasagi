module Chorg::Loggable
  extend ActiveSupport::Concern

  def logger
    @logger ||= Rails.logger
  end

  def cur_depth
    @log_deth ||= 0
  end

  def inc_depth
    cur_depth
    @log_deth += 1
  end

  def dec_depth
    cur_depth
    @log_deth -= 1
  end

  def log_indentation
    " " * cur_depth * 2
  end

  def put_log(message)
    logger.info("#{log_indentation}#{message}")
  end

  def put_warn(message)
    logger.warn("#{log_indentation}#{message}")
  end

  def put_error(message)
    logger.error("#{log_indentation}#{message}")
  end

  def with_inc_depth
    inc_depth
    begin
      yield
    ensure
      dec_depth
    end
  end
end
