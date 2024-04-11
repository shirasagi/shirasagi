def capture_twitter_rest_client(tweet_id: nil, username: nil)
  tweet_id ||= rand(100)
  username ||= "user_screen_id"

  capture = OpenStruct.new
  capture.update = OpenStruct.new(count: 0, tweet: nil)
  capture.user = OpenStruct.new(count: 0)
  capture.destroy_status = OpenStruct.new(count: 0)

  WebMock.reset!
  # WebMock.disable_net_connect!(allow_localhost: true)

  WebMock.stub_request(:post, "https://api.twitter.com/2/tweets").to_return do |request|
    capture.update.count += 1
    body = JSON.parse(request.body)
    capture.update.tweet = body["text"]

    response = { data: { id: tweet_id, text: body["text"] } }
    tweet_id += 1
    { status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' } }
  end
  url = Addressable::Template.new("https://api.twitter.com/2/tweets/{id}")
  WebMock.stub_request(:delete, url).to_return do |request|
    capture.destroy_status.count += 1

    response = { data: { deleted: true } }
    { status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' } }
  end
  WebMock.stub_request(:get, "https://api.twitter.com/2/users/me").to_return do |request|
    capture.user.count += 1

    response = {
      data: {
        id: rand(100),
        name: username,
        username: username,
      }
    }
    { status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' } }
  end

  yield(capture)

ensure
  WebMock.allow_net_connect!
end
