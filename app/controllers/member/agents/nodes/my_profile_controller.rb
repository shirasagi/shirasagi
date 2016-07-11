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

    def fix_params
      params = {}
      params[:kana_required] = true if @cur_node.kana_required?
      params[:organization_name_required] = true if @cur_node.organization_name_required?
      params[:job_required] = true if @cur_node.job_required?
      params[:postal_code_required] = true if @cur_node.postal_code_required?
      params[:tel_required] = true if @cur_node.tel_required?
      params[:addr_required] = true if @cur_node.addr_required?
      params[:sex_required] = true if @cur_node.sex_required?
      params[:birthday_required] = true if @cur_node.birthday_required?
      params
    end

    def validate_password_params
      if params[:item][:in_password].blank?
        @item.errors.add :in_password, I18n.t("errors.messages.not_input")
        return false
      end

      if params[:item][:new_password].blank?
        @item.errors.add I18n.t("member.view.new_password"), I18n.t("errors.messages.not_input")
        return false
      end

      if params[:item][:new_password_again].blank?
        @item.errors.add I18n.t("member.view.new_password_again"), I18n.t("errors.messages.not_input")
        return false
      end

      if params[:item][:new_password] != params[:item][:new_password_again]
        @item.errors.add I18n.t("member.view.new_password"), I18n.t("errors.messages.mismatch")
        return false
      end

      if @item.password != SS::Crypt.crypt(params[:item][:in_password])
        @item.errors.add I18n.t("member.view.old_password"), I18n.t("errors.messages.mismatch")
        return false
      end

      return true
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

      unless validate_password_params
        render action: :change_password
        return
      end

      @item.in_password = params[:item][:new_password]
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
