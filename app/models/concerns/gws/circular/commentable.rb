module Gws::Circular::Commentable
  extend ActiveSupport::Concern

  included do
    field :_comments, type: Array, default: []
  end

  # 回覧板へのコメントを許可しているか？
  # ・コメントを編集する権限を持っている
  # ・ユーザーもしくはメンバーに含まれる
  def permit_comment?(*args)
    opts = {user: user, site: site}.merge(args.extract_options!)

    self.class.allowed?(:edit, opts[:user], site: opts[:site]) &&
      (user_ids.include?(opts[:user].id) || member?(opts[:user]))
  end

  def commented?(u=user)
    comments.find { |c| c.user_id == u.id }
  end

  def add_comment(comment_hash)
    self._comments = _comments << comment_hash
    self
  end

  def update_comment(idx, comment_hash)
    _comments[idx] = comment_hash
    self._comments = _comments
    self
  end

  def delete_comment(idx)
    _comments.delete_at(idx)
    self._comments = _comments
    self
  end

  def comments
    attributes[:_comments].map.with_index do |comment, idx|
      comment[:id] = idx
      Gws::Circular::Comment.new comment
    end
  end

end
