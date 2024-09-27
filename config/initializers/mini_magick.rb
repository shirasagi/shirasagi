MiniMagick.configure do |config|
  cli_prefix = SS.config.env.mini_magick_cli_prefix.try(:presence)
  config.cli_prefix = cli_prefix if cli_prefix
end

MiniMagick.logger = Rails.logger
