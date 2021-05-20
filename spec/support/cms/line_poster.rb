def capture_line_bot_client
  capture = OpenStruct.new

  capture.broadcast = OpenStruct.new(count: 0)
  allow_any_instance_of(Line::Bot::Client).to receive(:broadcast) do |*args|
    capture.broadcast.count += 1
    capture.broadcast.messages = args[1]
    Net::HTTPOK.new("1.1", "200", "")
  end
  yield(capture)
end
