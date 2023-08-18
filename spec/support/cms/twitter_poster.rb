def capture_twitter_rest_client
  capture = OpenStruct.new

  capture.update_with_media = OpenStruct.new(count: 0)
  allow_any_instance_of(Twitter::REST::Client).to receive(:update_with_media) do |*args|
    capture.update_with_media.count += 1
    capture.update_with_media.tweet = args[1]
    capture.update_with_media.media_files = args[2]
    OpenStruct.new(id: "twitter_id")
  end

  capture.update = OpenStruct.new(count: 0)
  allow_any_instance_of(Twitter::REST::Client).to receive(:update) do |*args|
    capture.update.count += 1
    capture.update.tweet = args[1]
    OpenStruct.new(id: "twitter_id")
  end

  capture.user = OpenStruct.new(count: 0)
  allow_any_instance_of(Twitter::REST::Client).to receive(:user) do |*args|
    capture.user.count += 1
    OpenStruct.new(screen_name: "user_screen_id")
  end

  capture.destroy_status = OpenStruct.new(count: 0)
  allow_any_instance_of(Twitter::REST::Client).to receive(:destroy_status) do |*args|
    capture.destroy_status.count += 1
    capture.destroy_status.post_id = args[1]
    true
  end

  yield(capture)
end
