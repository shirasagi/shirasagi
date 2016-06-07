class Member::Agents::Nodes::MyProfileController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Cms::PublicFilter::Crud
  include Member::PostalCodeFilter

  model Cms::Member
  helper Member::MypageHelper

  before_action :set_item

  prepend_view_path "app/views/member/agents/nodes/my_profile"

  private
    def set_item
      @item = @cur_member
    end

  public
    def index
    end

    # 退会
    def leave
    end

    # 退会確認
    def confirm_leave
      # 戻るボタンがクリックされた
      if params[:back]
        redirect_to @cur_node.url
        return
      end

      if params[:item][:in_password].blank?
        @item.errors.add :in_password, I18n.t("errors.messages.not_input")
        render action: :leave
        return
      end

      if @item.password != SS::Crypt.crypt(params[:item][:in_password])
        @item.errors.add :in_password, I18n.t("errors.messages.mismatch")
        render action: :leave
        return
      end
    end

    # 退会完了
    def complete_leave
      # 戻るボタンがクリックされた
      if params[:back]
        redirect_to @cur_node.url
        return
      end

      @item.delete_leave_member_data(@cur_site)
      clear_member
      @item.destroy
    end

    # パスワード変更
    def change_password
    end

    def confirm_password
      # 戻るボタンがクリックされた
      if params[:back]
        redirect_to @cur_node.url
        return
      end

      if params[:item][:in_password].blank?
        @item.errors.add :in_password, I18n.t("errors.messages.not_input")
        render action: :change_password
        return
      end

      if params[:item][:new_password].blank?
        @item.errors.add I18n.t("member.view.new_password"), I18n.t("errors.messages.not_input")
        render action: :change_password
        return
      end

      if params[:item][:new_password_again].blank?
        @item.errors.add I18n.t("member.view.new_password_again"), I18n.t("errors.messages.not_input")
        render action: :change_password
        return
      end

      if params[:item][:new_password] != params[:item][:new_password_again]
        @item.errors.add I18n.t("member.view.new_password"), I18n.t("errors.messages.mismatch")
        render action: :change_password
        return
      end

      if @item.password != SS::Crypt.crypt(params[:item][:in_password])
        @item.errors.add :in_password, I18n.t("errors.messages.mismatch")
        render action: :change_password
        return
      end

      @item.in_password = params[:item][:new_password]
      @item.in_password_again = params[:item][:new_password_again]
      @item.encrypt_password

      unless @item.update
        render :change_password
        return
      end

      redirect_to "#{@cur_node.url}complete_password"
    end

    def complete_password
    end
end
