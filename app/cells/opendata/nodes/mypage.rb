# coding: utf-8
module Opendata::Nodes::Mypage
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Mypage
  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include Opendata::MypageFilter

    skip_filter :logged_in?, only: [:login, :logout]

    private
      def get_params
        params.require(:item).permit(:email, :password)
      end

    public
      def index
        controller.redirect_to "/mypage/dataset/" if @cur_member
      end

      def login
        @item = Cms::Member.new
        return render unless request.post?

        @item.attributes = get_params
        member = Cms::Member.where(email: @item.email, password: SS::Crypt.crypt(@item.password)).first
        return render if !member

        set_member member, session: true, redirect: true
      end

      def logout
        unset_member redirect: true
      end
  end
end
