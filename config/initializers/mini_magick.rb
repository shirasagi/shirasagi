MiniMagick.configure do |config|
  case SS.config.env.mini_magick_cli.to_s.downcase
  when "imagemagick"
    cli = :imagemagick
  when "imagemagick7"
    cli = :imagemagick7
  when "graphicsmagick"
    cli = :graphicsmagick
  else
    # auto detect
    cli = nil
  end

  config.cli = cli if cli
end

MiniMagick.logger = Rails.logger
