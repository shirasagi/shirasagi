class Gws::Circular::SetCommentAuthorityJob < Gws::ApplicationJob

  def perform(opts = {})
    Gws::Circular::Comment.where(browsing_authority: nil).update_all(browsing_authority: 'all')
  end
end
