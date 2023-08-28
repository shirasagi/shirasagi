puts "# member_blog"
file = save_ss_files "ss_files/key-visual/keyvisual01.jpg", filename: "keyvisual01.jpg", model: "member/blog_page"
blog_page = save_page route: "member/blog_page", filename: "kanko-info/blog/shirasagi/page1.html", name: "初投稿です。",
  member_id: @member_1.id,
  genres: %w(ジャンル1 ジャンル2 ジャンル3)

blog_page.file_ids = [file.id]
blog_page.html = blog_page.html.sub("src=\"#\"", "src=\"#{file.url}\"")
blog_page.update
