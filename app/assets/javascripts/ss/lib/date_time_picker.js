this.SS_DateTimePicker = (function () {
  // 注意:
  // datetimepicker にはバグがある。
  // このコントールの次の要素が disabled の場合、コントロール内で Enter キーを押しても、入力した日時が確定しない。
  //
  // datetimepicker では、コントロール内で Enter キーを押すと次の要素にフォーカスを移動させる。
  // フォーカスを移動させることでイベント "blur" が発生し、入力が確定 → onChangeDateTime イベント発生という順で処理が進む。
  //
  // しかし、次の要素が disabled の場合、フォーカスを移動させれず、イベント "blur" が発生しない。
  // このため、入力が確定せず、onChangeDateTime イベントも発生しない。
  //
  // 問題となるソースコードは https://github.com/xdan/datetimepicker/blob/master/jquery.datetimepicker.js#L2591
  // 要素セレクターに ":enabled" の条件がない。
  //
  // そこで、Enter キーが押されたら、イベント "blur" を発生させ、入力が確定 → onChangeDateTime イベント発生という順で処理が進むようにする。
  // また、念の為 Enter キーでフォーカスを移動させないようにするため enterLikeTab を false にする。
  function SS_DateTimePicker(el, type) {
    this.$el = $(el);

    if (!type) {
      if (this.$el.hasClass("js-date")) {
        type = "date"
      } else {
        type = "datetime"
      }
    }
    this.type = type;
    this.initialized = false;
    // this.ee = new EventEmitter3();

    this.render();
    this.$el.data("ss_datetimepicker", this);
  }

  var standardFormats = {
    RFC_2822: 'D, d M Y H:i:s O',
    ATOM: 'Y-m-dTH:i:sP',
    ISO_8601: 'Y-m-dTH:i:sO',
    RFC_822: 'D, d M y H:i:s O',
    RFC_850: 'l, d-M-y H:i:s T',
    RFC_1036: 'D, d M y H:i:s O',
    RFC_1123: 'D, d M Y H:i:s O',
    RSS: 'D, d M Y H:i:s O',
    W3C: 'Y-m-dTH:i:sP'
  }

  var isFormatStandard = function(format){
    return Object.values(standardFormats).indexOf(format) === -1 ? false : true;
  }

  var dateFormatter = {
    parseDate: function (date, format) {
      // 全角半角変換
      if (typeof date === "string") {
        date = date.replace(/[０-９]/g, function(s) {
          return String.fromCharCode(s.charCodeAt(0) - 0xFEE0);
        });
      }

      if(isFormatStandard(format)){
        return defaultDateHelper.parseDate(date, format);
      }
      var d = moment(date, format);
      return d.isValid() ? d.toDate() : false;
    },

    formatDate: function (date, format) {
      if(isFormatStandard(format)){
        return defaultDateHelper.formatDate(date, format);
      }
      return moment(date).format(format);
    },

    formatMask: function(format){
      return format
        .replace(/Y{4}/g, '9999')
        .replace(/Y{2}/g, '99')
        .replace(/M{2}/g, '19')
        .replace(/D{2}/g, '39')
        .replace(/H{2}/g, '29')
        .replace(/m{2}/g, '59')
        .replace(/s{2}/g, '59');
    }
  };

  var dateFormat = function() {
    if ("i18next" in window) {
      return i18next.t("date.formats.picker")
    } else {
      return SS.DEFAULT_DATE_FORMAT;
    }
  }

  var timeFormat = function() {
    if ("i18next" in window) {
      return i18next.t("time.formats.picker")
    } else {
      return SS.DEFAULT_TIME_FORMAT;
    }
  }

  var initialized = false;

  SS_DateTimePicker.renderOnce = function () {
    if (initialized) {
      return;
    }

    $.datetimepicker.setLocale(document.documentElement.lang || 'ja');
    // setLocale() を呼び出すと dateFormatter がリセットされるので、setLocale() の後に setDateFormatter() を呼び出さなければならない。
    $.datetimepicker.setDateFormatter(dateFormatter);

    initialized = true;
  };

  SS_DateTimePicker.render = function (root, type) {
    SS_DateTimePicker.renderOnce();

    $(root || document).find(".js-date,.js-datetime").each(function () {
      var $this = $(this);
      var data = $this.data();
      if ("ss_datetimepicker" in data) {
        // already instantiated
        return;
      }

      new SS_DateTimePicker(this, type);
    });
  };

  SS_DateTimePicker.instance = function (selector) {
    return $(selector).data("ss_datetimepicker");
  };

  // [ "on", "once", "off", "momentValue", "valueForExchange" ].forEach(function(method) {
  [ "momentValue", "valueForExchange" ].forEach(function(method) {
    SS_DateTimePicker[method] = function() {
      var selector = Array.prototype.shift.call(arguments)
      return SS_DateTimePicker.prototype[method].apply(SS_DateTimePicker.instance(selector), arguments);
    };
  });

  SS_DateTimePicker.prototype.render = function () {
    var self = this;

    var options = self.type === "date" ? self.buildDatePickerOptions() : self.buildDateTimePickerOptions();
    self.$el
      .attr('autocomplete', 'off')
      .datetimepicker(options)
      .on("keydown", function(ev) {
        var key = ev.which;
        if (key === SS.KEY_ENTER) {
          $this.trigger("blur.xdsoft")
        }
        return true;
      });

    self.$el.one("ss:generate", function() { self.onInitialized(); });

    var $form = this.$el.closest("form");
    if (!$form.data("ss-datetime-picker-installed")) {
      $form.data("ss-datetime-picker-installed", true);
    }
  };

  SS_DateTimePicker.prototype.onInitialized = function () {
    this.initialized = true;
  };

  SS_DateTimePicker.prototype.momentValue = function(value) {
    var self = this;

    if (arguments.length === 1) {
      // setter
      if (value) {
        value = self.type === "datetime" ? SS.formatTime(value, "picker") : SS.formatDate(value, "picker")
      }
      self.$el.val(value || '');
      self.$el.datetimepicker({ value: value || '' });
    } else {
      // getter
      // datetimepicker のバグだと思うが、初期化時に value が nil や空文字の場合、getValue がカレント時刻になってしまう。
      // 表示されている値（input の value)と、内部の値（datetimepicker の getValue）とが異なる場合を考慮する。
      if (!self.$el.val()) {
        return null;
      }

      var ret = self.$el.datetimepicker("getValue");
      if (!ret) {
        return ret;
      }

      return moment(ret);
    }
  };

  SS_DateTimePicker.prototype.valueForExchange = function () {
    var self = this;

    var value = self.momentValue();
    if (value) {
      value = value.format(this.type === "datetime" ? "YYYY/MM/DD HH:mm:ss" : "YYYY/MM/DD");
    }

    return value || '';
  };

  SS_DateTimePicker.prototype.buildDatePickerOptions = function () {
    var self = this;
    var opts = {
      format: SS.convertDateTimeFormat(dateFormat()),
      formatDate: SS.convertDateTimeFormat(dateFormat()),
      formatTime: "HH:mm",
      value: self.$el.val(),
      enterLikeTab: false,
      timepicker: false,
      closeOnDateSelect: true,
      scrollInput: false,
      onGenerate: function() { self.$el.trigger("ss:generate"); },
      onChangeDateTime: function(currentTime, $input, ev) {
        self.$el.trigger("ss:changeDateTime", [ currentTime, $input, ev ]);
      }
    };

    var data = self.$el.data();
    if (data.format) {
      opts.format = SS.convertDateTimeFormat(data.format);
    }
    if ("closeOnDateSelect" in data) {
      opts.closeOnDateSelect = data.closeOnDateSelect;
    }
    if ("scrollInput" in data) {
      opts.scrollInput = data.scrollInput;
    }
    if (data.minDate) {
      opts.minDate = data.minDate;
    }
    if (data.maxDate) {
      opts.maxDate = data.maxDate;
    }

    return opts;
  };

  SS_DateTimePicker.prototype.buildDateTimePickerOptions = function () {
    var self = this;
    var opts = {
      format: SS.convertDateTimeFormat(timeFormat()),
      formatDate: SS.convertDateTimeFormat(dateFormat()),
      formatTime: "HH:mm",
      value: self.$el.val(),
      closeOnDateSelect: false,
      enterLikeTab: false,
      scrollInput: false,
      roundTime: 'ceil',
      step: 30,
      onGenerate: function() { self.$el.trigger("ss:generate"); },
      onChangeDateTime: function(currentTime, $input, ev) {
        self.$el.trigger("ss:changeDateTime", [ currentTime, $input, ev ]);
      }
    };

    var data = self.$el.data();
    if (data.format) {
      opts.format = SS.convertDateTimeFormat(data.format);
    }
    if (data.minDate) {
      opts.minDate = data.minDate;
    }
    if (data.maxDate) {
      opts.maxDate = data.maxDate;
    }
    if ("closeOnDateSelect" in data) {
      opts.closeOnDateSelect = data.closeOnDateSelect;
    }
    if ("scrollInput" in data) {
      opts.scrollInput = data.scrollInput;
    }
    // time specific options
    if (data.step) {
      opts.step = data.step;
    }
    if (data.roundTime) {
      opts.roundTime = data.roundTime;
    }

    return opts;
  };

  return SS_DateTimePicker;
})();
