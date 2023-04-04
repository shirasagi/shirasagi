module Member
  class Initializer
    # login node
    Cms::Node.plugin "member/login"

    # registration node
    Cms::Node.plugin "member/registration"

    # mypage nodes
    Cms::Node.plugin "member/mypage"
    Cms::Node.plugin "member/my_profile"
    Cms::Node.plugin "member/my_blog"
    Cms::Node.plugin "member/my_photo"

    # public nodes
    Cms::Node.plugin "member/blog"
    Cms::Node.plugin "member/blog_page_location"
    Cms::Node.plugin "member/photo"
    Cms::Node.plugin "member/photo_search"
    Cms::Node.plugin "member/photo_category"
    Cms::Node.plugin "member/photo_location"
    Cms::Node.plugin "member/photo_spot"
    Cms::Node.plugin "member/bookmark"

    # anpi
    Cms::Node.plugin "member/my_anpi_post"
    Cms::Node.plugin "member/my_group"

    Cms::Part.plugin "member/login"
    Cms::Part.plugin "member/blog_page"
    Cms::Part.plugin "member/photo"
    Cms::Part.plugin "member/photo_search"
    Cms::Part.plugin "member/photo_slide"
    Cms::Part.plugin "member/invited_group"
    Cms::Part.plugin "member/bookmark"

    # line
    Cms::Node.plugin "member/my_line_profile"
    Cms::Node.plugin "member/line_first_registration"

    Cms::Role.permission :read_other_member_blogs
    Cms::Role.permission :read_private_member_blogs
    Cms::Role.permission :edit_other_member_blogs
    Cms::Role.permission :edit_private_member_blogs
    Cms::Role.permission :delete_other_member_blogs
    Cms::Role.permission :delete_private_member_blogs
    Cms::Role.permission :release_other_member_blogs
    Cms::Role.permission :release_private_member_blogs
    Cms::Role.permission :close_other_member_blogs
    Cms::Role.permission :close_private_member_blogs
    Cms::Role.permission :approve_other_member_blogs
    Cms::Role.permission :approve_private_member_blogs
    Cms::Role.permission :reroute_other_member_blogs
    Cms::Role.permission :reroute_private_member_blogs
    Cms::Role.permission :revoke_other_member_blogs
    Cms::Role.permission :revoke_private_member_blogs

    Cms::Role.permission :read_other_member_photos
    Cms::Role.permission :read_private_member_photos
    Cms::Role.permission :edit_other_member_photos
    Cms::Role.permission :edit_private_member_photos
    Cms::Role.permission :delete_other_member_photos
    Cms::Role.permission :delete_private_member_photos
    Cms::Role.permission :release_other_member_photos
    Cms::Role.permission :release_private_member_photos
    Cms::Role.permission :close_other_member_photos
    Cms::Role.permission :close_private_member_photos
    Cms::Role.permission :approve_other_member_photos
    Cms::Role.permission :approve_private_member_photos
    Cms::Role.permission :reroute_other_member_photos
    Cms::Role.permission :reroute_private_member_photos
    Cms::Role.permission :revoke_other_member_photos
    Cms::Role.permission :revoke_private_member_photos

    SS::File.model "member/photo", Member::PhotoFile, permit: %i(role)
    SS::File.model "member/blog_page", Member::File, permit: %i(role)
    SS::File.model "member/temp_file", Member::File
    SS::File.model "member/node/blog_page", SS::File, permit: %i(role)
  end
end
