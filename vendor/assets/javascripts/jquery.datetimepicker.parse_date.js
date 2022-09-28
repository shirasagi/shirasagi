/*!
  * override original DateFormatter's parseDate
  * @version 1.3.3
*/
DateFormatter.prototype.parseDate = function (vDate, vFormat) {
  var self = this, vFormatParts, vDateParts, i, vDateFlag = false, vTimeFlag = false, vDatePart, iDatePart,
    vSettings = self.dateSettings, vMonth, vMeriIndex, vMeriOffset, len, mer,
    out = {date: null, year: null, month: null, day: null, hour: 0, min: 0, sec: 0};
  if (!vDate) {
    return undefined;
  }
  if (vDate instanceof Date) {
    return vDate;
  }
  if (typeof vDate === 'number') {
    return new Date(vDate);
  }
  if (vFormat === 'U') {
    i = parseInt(vDate);
    return i ? new Date(i * 1000) : vDate;
  }
  if (typeof vDate !== 'string') {
    return '';
  }
  vFormatParts = vFormat.match(self.validParts);
  if (!vFormatParts || vFormatParts.length === 0) {
    throw new Error("Invalid date format definition.");
  }

  // 全角半角変換
  vDate = vDate.replace(/[０-９]/g, function(s) {
    return String.fromCharCode(s.charCodeAt(0) - 0xFEE0);
  });

  vDateParts = vDate.replace(self.separators, '\0').split('\0');

  // フォーマットのParts数と実際のParts数が異なっていれば不正とみなす
  if (vDateParts.length != vFormatParts.length) {
    return false;
  }
  // Partsの中に数字以外の文字があれば不正とみなす
  for (i = 0; i < vDateParts.length; i++) {
    if (!vDateParts[i].match(/^\d+$/)) {
       return false;
    }
  }

  for (i = 0; i < vDateParts.length; i++) {
    vDatePart = vDateParts[i];
    iDatePart = parseInt(vDatePart);
    switch (vFormatParts[i]) {
      case 'y':
      case 'Y':
        len = vDatePart.length;
        if (len === 2) {
          out.year = parseInt((iDatePart < 70 ? '20' : '19') + vDatePart);
        } else if (len === 4) {
          out.year = iDatePart;
        }
        vDateFlag = true;
        break;
      case 'm':
      case 'n':
      case 'M':
      case 'F':
        if (isNaN(vDatePart)) {
          vMonth = vSettings.monthsShort.indexOf(vDatePart);
          if (vMonth > -1) {
            out.month = vMonth + 1;
          }
          vMonth = vSettings.months.indexOf(vDatePart);
          if (vMonth > -1) {
            out.month = vMonth + 1;
          }
        } else {
          if (iDatePart >= 1 && iDatePart <= 12) {
            out.month = iDatePart;
          }
        }
        vDateFlag = true;
        break;
      case 'd':
      case 'j':
        if (iDatePart >= 1 && iDatePart <= 31) {
          out.day = iDatePart;
        }
        vDateFlag = true;
        break;
      case 'g':
      case 'h':
        vMeriIndex = (vFormatParts.indexOf('a') > -1) ? vFormatParts.indexOf('a') :
          (vFormatParts.indexOf('A') > -1) ? vFormatParts.indexOf('A') : -1;
        mer = vDateParts[vMeriIndex];
        if (vMeriIndex > -1) {
          vMeriOffset = _compare(mer, vSettings.meridiem[0]) ? 0 :
            (_compare(mer, vSettings.meridiem[1]) ? 12 : -1);
          if (iDatePart >= 1 && iDatePart <= 12 && vMeriOffset > -1) {
            out.hour = iDatePart + vMeriOffset;
          } else if (iDatePart >= 0 && iDatePart <= 23) {
            out.hour = iDatePart;
          }
        } else if (iDatePart >= 0 && iDatePart <= 23) {
          out.hour = iDatePart;
        }
        vTimeFlag = true;
        break;
      case 'G':
      case 'H':
        if (iDatePart >= 0 && iDatePart <= 23) {
          out.hour = iDatePart;
        }
        vTimeFlag = true;
        break;
      case 'i':
        if (iDatePart >= 0 && iDatePart <= 59) {
          out.min = iDatePart;
        }
        vTimeFlag = true;
        break;
      case 's':
        if (iDatePart >= 0 && iDatePart <= 59) {
          out.sec = iDatePart;
        }
        vTimeFlag = true;
        break;
    }
  }
  if (vDateFlag === true && out.year && out.month && out.day) {
    out.date = new Date(out.year, out.month - 1, out.day, out.hour, out.min, out.sec, 0);
  } else {
    if (vTimeFlag !== true) {
      return false;
    }
    out.date = new Date(0, 0, 0, out.hour, out.min, out.sec, 0);
  }
  return out.date;
}
