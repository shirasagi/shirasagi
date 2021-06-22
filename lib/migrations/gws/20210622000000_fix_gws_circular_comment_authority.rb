class SS::Migration20210622000000
  include SS::Migration::Base

  depends_on "20210212000000"

  def change
    Gws::Circular::Comment.where(:post_id.exists => true, browsing_authority: nil).each do |comment|
      comment.set(browsing_authority: "all")
    end
  end
end
