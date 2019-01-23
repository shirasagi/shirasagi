$(document).on('click', 'button#create-table', function () {
  var table_editor = $('#table-editor');
  var width = parseInt($('#width').val());
  var height = parseInt($('#height').val());
  var header = $('#header').val();
  var table = $('<table></table>')
  var tbody = $("<tbody></tbody>")
  var tr = "";
  for (var i=0; i<height; i++) {
    tr = tr + "<tr>";
    for (var j=0; j<width; j++) {
      if (header == "top"){
        if (i == 0) {
          tr = tr + "<th></th>";
        }else{
          tr = tr + "<td></td>";
        }
      }else if (header == "left"){
        if (j == 0) {
          tr = tr + "<th></th>";
        }else{
          tr = tr + "<td></td>";
        }
      }else if (header == "top-left"){
        if (j == 0 || i == 0) {
          tr = tr + "<th></th>";
        }else{
          tr = tr + "<td></td>";
        }
      }else{
        tr = tr + "<td></td>";
      }
    }
    tr = tr + "</tr>";
  }

  tbody.append(tr)
  table.append(tbody);

  table_editor.html(table);
});

$(document).on('click', 'td, th', function () {
  var editable = $(this);

  // セルをクリックしたら取得したセルの値をtextareaに追加してセル内にtextareaを挿入
  editable.html('<textarea style="width:100%">' + editable.html() + '</textarea>').find('textarea')
      .focus()
      .on('blur', function () {
        // フォーカスが外れた時、セルに値を追加して不要なtextareaを削除
        editable.append($(this).val());
        editable.find('textarea').remove();
        $('#item_column_values__in_wrap_value').val($('#table-editor').html())
      })
      .on('click', function (e) {
        e.stopPropagation();
      });
});

$(document).on('contextmenu', '#table-editor td, #table-editor th', function (e){
  var tableMenu = $('#table-menu');
  var tableEditor = $('#table-editor');
  tableMenu.addClass('show');
  tableMenu.offset({
    top: e.pageY,
    left: e.pageX
  })
  tableDom = $(this);
});

$(document).on('click', 'body', function (){
  var tableMenu = $('#table-menu');
  if(tableMenu.hasClass('show')) {
    tableMenu.removeClass('show');
  }
});

$(document).on('click', '#table-menu #change-th', function (){
  tableDom.replaceWith("<th>"+ tableDom.html() +"</th>");
});

$(document).on('click', '#table-menu #change-td', function (){
  tableDom.replaceWith("<td>"+ tableDom.html() +"</td>");
});

$(document).on('click', '#table-menu #remove-tr', function (){
  tableDom.parent().remove();
});

$(document).on('click', '#table-menu #remove-tds', function (){
  var cellIndex = tableDom[0].cellIndex;
  var table = tableDom.parent().parent();
  for (var i=0; i<table[0].rows.length; i++){
    table[0].rows[i].cells[cellIndex].remove();
  }
});

$(document).on('click', '#table-menu #append-top', function (){
  var table = tableDom.parent().parent();
  var columnNum = table[0].rows[0].cells.length;
  var newTr = "<tr>";
  for (var i=0; i<columnNum; i++) {
    newTr = newTr + "<td></td>";
  }
  newTr = newTr + "</tr>";
  tableDom.parent().before(newTr);
});

$(document).on('click', '#table-menu #append-bottom', function (){
  var table = tableDom.parent().parent();
  var columnNum = table[0].rows[0].cells.length;
  var newTr = "<tr>";
  for (var i=0; i<columnNum; i++) {
    newTr = newTr + "<td></td>";
  }
  newTr = newTr + "</tr>";
  tableDom.parent().after(newTr);
});

$(document).on('click', '#table-menu #append-right', function (){
  var cellIndex = tableDom[0].cellIndex;
  var table = tableDom.parent().parent();
  for (var i=0; i<table[0].rows.length; i++){
    if (table[0].rows[i].cells[cellIndex].tagName == "TH") {
      $(table[0].rows[i].cells[cellIndex]).after("<th></th>");
    }else{
      $(table[0].rows[i].cells[cellIndex]).after("<td></td>");
    }
  }
});

$(document).on('click', '#table-menu #append-left', function (){
  var cellIndex = tableDom[0].cellIndex;
  var table = tableDom.parent().parent();
  for (var i=0; i<table[0].rows.length; i++){
    if (table[0].rows[i].cells[cellIndex].tagName == "TH") {
      $(table[0].rows[i].cells[cellIndex]).before("<th></th>");
    }else{
      $(table[0].rows[i].cells[cellIndex]).before("<td></td>");
    }
  }
});
