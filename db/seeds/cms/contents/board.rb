puts "# board"

def save_board_post(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name], poster: data[:poster] }
  item = Board::Post.where(cond).first || Board::Post.new
  item.attributes = data
  item.save

  item
end
