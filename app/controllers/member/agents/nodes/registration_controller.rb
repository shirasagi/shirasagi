class Member::Agents::Nodes::RegistrationController < ApplicationController
  include Cms::NodeFilter::View
  include Member::PostalCodeFilter

  model Cms::Member
  helper Member::MypageHelper

  after_action :try_to_join_group, only: :registration

  private
    def fix_params
      { cur_site: @cur_site }
    end

    def permit_fields
      @model.permitted_fields
    end

    def get_params
      params.require(:item).permit(permit_fields).merge(fix_params)
    end

    def try_to_join_group
      group_id = params[:group].presence
      return if group_id.blank?

      group_id = SS::Crypt.decrypt(group_id) rescue nil
      return if group_id.blank?

      group = Member::Group.site(@cur_site).where(id: group_id).first
      return if group.blank?

      return if @item.errors.present?

      group.accept(@item)
    end

  public
    # 新規登録
    def new
      @item = @model.new
    end

    # 入力確認
    def confirm
      @item = @model.new get_params
      @item.in_check_name = true
      @item.in_check_email_again = true
      @item.set_required @cur_node
      @item.state = 'temporary'

      render action: :new unless @item.valid?
    end

    # 仮登録完了
    def interim
      @item = @model.new get_params
      @item.in_check_name = true
      @item.set_required @cur_node
      @item.state = 'temporary'

      # 戻るボタンのクリック
      unless params[:submit]
        render action: :new
        return
      end

      if @cur_node.confirm_personal_data_state == 'enabled'
        if @item.in_confirm_personal_info != 'yes'
          @item.errors.add :base, I18n.t("errors.messages.please_confirm_personal_data_protection")
          render action: :confirm
          return
        end
      end

      render action: :new unless @item.save
    end

    # 確認メールのURLをクリック
    def verify
      @item = Cms::Member.site(@cur_site).and_verification_token(params[:token]).and_temporary.first
      raise "404" if @item.blank?
    end

    # 本登録
    def registration
      @item = Cms::Member.site(@cur_site).and_verification_token(params[:token]).and_temporary.first
      raise "404" if @item.blank?

      @item.attributes = get_params
      @item.in_check_password = true
      @item.set_required @cur_node
      @item.state = 'enabled'

      unless @item.update
        render action: :verify
        return
      end
    end

    def send_again
      @item = @model.new
    end

    def resend_confirmation_mail
      @item = @model.new get_params

      if @item.email.blank?
        @item.errors.add :email, I18n.t("errors.messages.not_input")
        render action: :send_again
        return
      end

      member = Cms::Member.site(@cur_site).where(email: @item.email).first
      if member.nil?
        @item.errors.add :email, I18n.t("errors.messages.not_registerd")
        render action: :send_again
        return
      end

      if member.authorized?
        @item.errors.add :email, I18n.t("errors.messages.already_registerd")
        render action: :send_again
        return
      end

      Member::Mailer.verification_mail(member).deliver_now

      redirect_to "#{@cur_node.url}send_again", notice: t("notice.resend_confirmation_mail")
    end

    # パスワード再設定
    def reset_password
      @item = Cms::Member.new
      return if request.get?

      @item = @model.new get_params

      if @item.email.blank?
        @item.errors.add :email, I18n.t("errors.messages.not_input")
        render action: :reset_password
        return
      elsif @item.in_password != @item.in_password_again
        @item.errors.add :email, :mismatch
        render action: :reset_password
        return
      end

      member = Cms::Member.site(@cur_site).and_enabled.where(email: @item.email).first
      if member.nil?
        @item.errors.add :email, I18n.t("errors.messages.not_registerd")
        render action: :reset_password
        return
      end

      Member::Mailer.reset_password_mail(member).deliver_now

      redirect_to "#{@cur_node.url}confirm_reset_password"
    end

    def confirm_reset_password
    end

    def change_password
      @item = Cms::Member.site(@cur_site).and_enabled.find_by_secure_id(params[:token]) rescue nil
      raise "404" unless @item.present?

      return if request.get?

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

      @item.in_password = params[:item][:new_password]
      @item.in_password_again = params[:item][:new_password_again]
      @item.encrypt_password

      unless @item.update
        render :change_password
        return
      end

      redirect_to "#{@cur_node.url}confirm_password"
    end

    def confirm_password
    end
end
