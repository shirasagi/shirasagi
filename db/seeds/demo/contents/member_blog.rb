puts "# member_blog"
file = save_ss_files "ss_files/key_visual/small/keyvisual01.jpg", filename: "keyvisual01.jpg", model: "member/blog_page"
blog_page = save_page route: "member/blog_page", filename: "kanko-info/blog/shirasagi/page1.html", name: "初投稿です。",
  member_id: @member_1.id,
  genres: %w(ジャンル1 ジャンル2 ジャンル3)

blog_page.file_ids = [file.id]
blog_page.html = blog_page.html.sub("src=\"#\"", "src=\"#{file.url}\"")
blog_page.update

file = save_ss_files "ss_files/key_visual/small/keyvisual01.jpg", filename: "keyvisual01.jpg", model: "member/blog_page"
blog_page = save_page route: "member/blog_page", filename: "kanko-info/blog/newblog/page1.html", name: "初投稿です。",
  member_id: @member_2.id,
  genres: %w(自治体ブログ), blog_page_location_ids: [@blog_l1.id, @blog_l3.id]

blog_page.file_ids = [file.id]
blog_page.html = blog_page.html.sub("src=\"#\"", "src=\"#{file.url}\"")
blog_page.update

save_page route: "member/blog_page", filename: "kanko-info/blog/newblog/page2.html", name: "あじさい祭りに行ってきました",
  member_id: @member_2.id,
  genres: %w(自治体ブログ), blog_page_location_ids: [@blog_l1.id]
