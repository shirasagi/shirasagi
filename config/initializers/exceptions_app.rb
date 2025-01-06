# .mypage error page
Rails.application.config.exceptions_app = ActionDispatch::PublicExceptions.new(File.join(Rails.public_path, ".error_pages"))
