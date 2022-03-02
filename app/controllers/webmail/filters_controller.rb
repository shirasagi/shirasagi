class Webmail::FiltersController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapCrudFilter

  model Webmail::Filter

  before_action :imap_login, except: [:index]
  before_action :check_group_imap_permissions, if: ->{ @webmail_mode == :group }

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/filter"), { action: :index } ]
    @webmail_other_account_path = :webmail_filters_path
  end

  def fix_params
    @imap.account_scope.merge(cur_user: @cur_user, imap: @imap)
  end

  def check_group_imap_permissions
    unless @cur_user.webmail_permitted_any?(:edit_webmail_group_imap_filters)
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode, account: params[:account])
    end
  end

  public

  def index
    @items = @model.
      and_imap(@imap).
      search(params[:s]).
      page(params[:page]).
      per(50)
  end

  def download
    s_params = params[:s] || {}

    @items = @model.
      and_imap(@imap).
      search(s_params)

    send_enum enum_csv, type: 'text/csv; charset=Shift_JIS', filename: "personal_filters_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get? || request.head?

    file = params[:item].try(:[], :in_file)
    if file.nil? || ::File.extname(file.original_filename) != ".csv"
      @item = @model.new
      @item.errors.add :base, I18n.t("errors.messages.invalid_csv")
      return false
    end

    conf = @imap_setting.imap_settings(@cur_user.imap_default_settings)
    SS::Csv.foreach_row(file, headers: true) do |row|
      conditions = row[@model.t(:conditions)].to_s.split("\n").collect do |value|
        JSON.parse(value, symbolize_names: true)
      end
      item = @model.find_or_initialize_by(
        host: conf[:host],
        account: conf[:account],
        conjunction: value(row, :conjunction),
        conditions: conditions,
        action: value(row, :action),
        mailbox: value(row, :mailbox),
        user_id: @cur_user.id
      )
      @model::EXPORT_ATTRIBUTES.each do |attribute|
        next if attribute == 'conditions'
        item.write_attribute(attribute, value(row, attribute))
      end
      item.save
    end

    render_update true, location: { action: :index }
  end

  def apply
    set_item

    mailbox = params[:mailbox].presence
    return render(template: "show") if mailbox.blank?

    @imap.examine(mailbox)
    uids = @item.uids_search([])
    count = @item.uids_apply(uids)
    return render(template: "show") if count == false

    @imap.mailboxes.update_status

    respond_to do |format|
      format.html { redirect_to({ action: :show }, notice: t('webmail.notice.multiple.filtered', count: count)) }
      format.json { head :no_content }
    end
  end

  private

  def enum_csv
    attributes = @model::EXPORT_ATTRIBUTES
    Enumerator.new do |y|
      y << encode(attributes.collect { |attribute| @model.t(attribute) })
      @items.each do |item|
        row = attributes.collect do |attribute|
          if attribute == 'conditions'
            item.send(attribute).collect(&:to_json).join("\n")
          else
            item.send(attribute)
          end
        end
        y << encode(row)
      end
    end
  end

  def encode(str)
    str.to_csv.encode('CP932', invalid: :replace, undef: :replace)
  end

  def value(row, key)
    row[@model.t(key)].try(:strip)
  end
end
