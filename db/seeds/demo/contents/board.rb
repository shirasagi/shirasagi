puts "# board"

def save_board_post(data)
  puts data[:name]
  cond = { site_id: data[:site_id], node_id: data[:node_id], name: data[:name], poster: data[:poster] }
  item = Board::Post.where(cond).first || Board::Post.new
  item.attributes = data
  item.save

  item
end

node = save_node route: "board/post", filename: "board", name: "災害掲示板", layout_id: @layouts["general"].id,
  mode: "tree", file_limit: 1, text_size_limit: 400, captcha: "enabled", deletable_post: "enabled",
  deny_url: "deny", file_size_limit: (1024 * 1024 * 2), file_scan: "disabled", show_email: "enabled",
  show_url: "enabled"
topic1 = save_board_post name: "テスト投稿", text: "テスト投稿です。", site_id: @site.id, node_id: node.id,
  poster: "白鷺　太郎", delete_key: 1234
comment1 = save_board_post name: "Re:テスト投稿", text: "返信します。", site_id: @site.id, node_id: node.id,
  poster: "鷺　智子", delete_key: 1234, parent_id: topic1.id, topic_id: topic1.id
comment2 = save_board_post name: "Re:テスト投稿", text: "返信します。", site_id: @site.id, node_id: node.id,
  poster: "黒鷺　次郎", delete_key: 1234, parent_id: topic1.id, topic_id: topic1.id
topic2 = save_board_post name: "タイトル", text: "投稿します。", site_id: @site.id, node_id: node.id,
  poster: "白鷺　太郎", delete_key: 1234

save_node route: "board/anpi_post", filename: "anpi", name: "安否掲示板", layout_id: @layouts["general"].id

user = Cms::User.first
if user
  file = save_ss_files "ss_files/article/pdf_file.pdf", filename: "file.pdf", model: "board/post", site_id: @site.id
  file.set(state: "public")
  topic3 = save_board_post name: "管理画面から", text: "管理画面からの投稿です。", site_id: @site.id, node_id: node.id,
    user_id: user.id, poster: "管理者", delete_key: 1234, poster_url: @link_url, file_ids: [file.id]
end
