var fullCalendar_renderListEvents = function(segs) {
  var firstOrCreateView = function () {
    var view = $('.fc-view .fc-listMonth-view-container')[0];
    if (view) {
      return $(view);
    }
    view = $('<div class="fc-listMonth-view-container"></div>').appendTo('.fc-view');
    return view;
  };
  var clearView = function (view) {
    view.html('');
    return view;
  };
  var updateNoPlanVisibility = function () {
    var noPlan = $('.fc-listMonth-view-container .no-plan');
    if ($('.fc-event:visible').length == 0) {
      noPlan.show();
    } else {
      noPlan.hide();
    }
  };
  var calendar = this.calendar;
  var view = clearView(firstOrCreateView());
  var table = $('<div class="fc-listMonth-view-table"></div>');
  var eventCount = 0;

  var noPlan = $('<div class="td no-plan" style="display: none;">' + Gws_Schedule_Calendar.messages.noPlan + '</div>');
  $('<div class="tr"></div>').appendTo(table).append(noPlan);

  for (var i = 0; i < segs.length; i++) {
    var seg = segs[i];
    var event = seg.event;

    if (event.className.indexOf('fc-holiday') !== -1) continue;

    var cont = $('<span class="fc-content"></span>').text(event.title);
    var evEl = $('<a class="fc-event fc-event-point"></a>').append(cont);

    evEl.addClass(event.className.join(' '));
    evEl.css({'color': event.textColor, 'background-color': event.backgroundColor});

    evEl.bind('click', function (ev) {
      var eventNo = $(this).data('eventNo');
      return calendar.view.trigger('eventClick', $(this), segs[eventNo].event, ev);
    }).data('eventNo', i);

    var info = $('<div class="td info"></div>').append(evEl);
    if (event.sanitizedHtml) {
      info.append('<p class="summary">' + event.sanitizedHtml + '</p>');
    }
    if (event.allDay) {
      var startLabel = event.startDateLabel + ' ' + event.allDayLabel;
      var endLabel = event.endDateLabel + ' ' + event.allDayLabel;
    }
    else {
      var startLabel = event.startDateLabel + ' ' + event.startTimeLabel;
      var endLabel = event.endDateLabel + ' ' + event.endTimeLabel;
    }
    var startAt = $('<div class="td startAt"></div>').text(startLabel);
    var delimiter = $('<div class="td delimiter"></div>').text('-');
    var endAt = $('<div class="td endAt"></div>').text(endLabel);
    var tr = $('<div class="tr"></div>').appendTo(table).append(startAt).append(delimiter).append(endAt).append(info);
    eventCount++;
    if (event.className.indexOf('fc-event-todo') !== -1) {
      tr.addClass('fc-event-todo');
    }
    if (event.className.indexOf('fc-event-user-attendance-absence') !== -1) {
      tr.addClass('fc-event-user-attendance-absence');
      tr.css('display', 'none');
    }
  }
  table.appendTo(view);
  updateNoPlanVisibility();

  //var installedWithTodoClick = false;
  //if (!installedWithTodoClick) {
  //  installedWithTodoClick = true;
  //  $('.fc-withTodo-button').on('click', function (e) {
  //    var viewName = $('#calendar').fullCalendar('getView').name;
  //    if (!viewName) {
  //      viewName = $('#calendar-controller').fullCalendar('getView').name;
  //    }
  //
  //    if (viewName === 'listMonth') {
  //      setTimeout(updateNoPlanVisibility, 0);
  //    }
  //  });
  //}
};

$.fullCalendar.toggleListFormat = function(selector) {
  if ($(selector).hasClass("fc-list-format")) {
    $(selector).find(".fc-view").children().show();
    $(selector).find(".fc-listMonth-view-container").hide();
    $(selector).removeClass("fc-list-format");
  }
  else {
    $(selector).find(".fc-view").children().hide();
    $(selector).find(".fc-listMonth-view-container").show();
    $(selector).addClass("fc-list-format");
  }
};

// basic
$.fullCalendar.BasicView.prototype.renderListEvents = fullCalendar_renderListEvents;
$.fullCalendar.BasicView.prototype.renderEvents_ = $.fullCalendar.BasicView.prototype.renderEvents;
$.fullCalendar.BasicView.prototype.renderEvents = function(events) {
  this.renderEvents_(events);
  if (this.el.closest(".fc").hasClass("fc-list-format")) {
    segs = this.dayGrid.segs;
    this.renderListEvents(segs);
  }
};

$.fullCalendar.BasicView.prototype.renderSkeletonHtml_ = $.fullCalendar.BasicView.prototype.renderSkeletonHtml;
$.fullCalendar.BasicView.prototype.renderSkeletonHtml = function() {
  var h = this.renderSkeletonHtml_();
  if (this.el.closest(".fc").hasClass("fc-list-format")) {
    h = $(h).hide()[0];
  }
  return h;
};

// agenda
$.fullCalendar.AgendaView.prototype.renderListEvents = fullCalendar_renderListEvents;
$.fullCalendar.AgendaView.prototype.renderEvents_ = $.fullCalendar.AgendaView.prototype.renderEvents;
$.fullCalendar.AgendaView.prototype.renderEvents = function(events) {
  this.renderEvents_(events);
  if (this.el.closest(".fc").hasClass("fc-list-format")) {
    segs = this.timeGrid.segs.concat(this.dayGrid.segs);
    this.renderListEvents(segs);
  }
};

$.fullCalendar.AgendaView.prototype.renderSkeletonHtml_ = $.fullCalendar.AgendaView.prototype.renderSkeletonHtml;
$.fullCalendar.AgendaView.prototype.renderSkeletonHtml = function() {
  var h = this.renderSkeletonHtml_();
  if (this.el.closest(".fc").hasClass("fc-list-format")) {
    h = $(h).hide()[0];
  }
  return h;
};
