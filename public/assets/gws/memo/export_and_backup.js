function Gws_Memo_ExportAndBackup($el) {
  this.$el = $el;

  this.render();
}

Gws_Memo_ExportAndBackup.prototype.render = function() {
  this.$el.find('a.ajax-box').data('on-select', function($item) {
    var $data       = $item.closest('[data-id]');
    var id          = $data.attr('data-id');
    var attachments = $data.data('attachments');
    var from        = $data.data('from');
    var name        = $data.data('name');
    var priority    = $data.data('priority');
    var send_date   = $data.data('send_date');
    var size        = $data.data('display_size');

    var $newTr    = $('<tr />').attr('data-id', id);
    var $newInput = SS_SearchUI.anchorAjaxBox.closest('dl').find('.hidden-ids').clone(false);
    $newInput     = $newInput.val(id).removeClass('hidden-ids');
    var $newA     = $('<a>').attr('class','deselect btn').attr('href','#').text('削除').on('click', SS_SearchUI.deselect);

    var icon = $('<i class="material-icons md-15">&#xE226;</i>');
    if (!attachments) {
      icon.css('visibility','hidden');
    }
    $newTr.append($('<td />').text(from).prepend(icon));
    $newTr.append($('<td />').append($newInput).append(name));
    $newTr.append($('<td />').text(priority));
    $newTr.append($('<td />').text(send_date));
    $newTr.append($('<td />').text(size));
    $newTr.append($('<td />').append($newA));
    SS_SearchUI.anchorAjaxBox.closest('dl').find('.ajax-selected tbody').prepend($newTr);
    SS_SearchUI.anchorAjaxBox.closest('dl').find('.ajax-selected').trigger('change');
  });
};
