Guide2_Form = function(containerClass) {
  this.container = document.querySelector(containerClass);
  this.questions = [];
  this.results = [];
  this.resultsUrl = null;
};

Guide2_Form.prototype.render = function() {
  this.initQuestions();
};

Guide2_Form.prototype.initQuestions = function() {
  this.questions = this.questions.map(question => {
    delete question.created;
    delete question.updated;
    delete question.deleted;
    delete question.text_index;

    question.answer = null;
    question.conditions = [];
    this.results.forEach(result => {
      let condition = result.conditions.find(c => c._id === question._id);
      question.conditions.push({
        _id: result._id,
        value: condition?.value,
        result: result
      });

      // result.conditions.forEach(condition => {
      //   if (condition._id !== question._id) return;
      //   condition.answer = null;

      //   //if (question.resultConditions.includes(condition.value)) return;
      //   //question.conditions.push(condition.value);
      // });
    });
    return question;
  })
  // this.answer_groups = {};

  this.next = null;
  console.log("#r:", this.results)
  console.log("#q:", this.questions)

  this.currentNo = -1; // remove
  this.nextQuestion();
};

Guide2_Form.prototype.nextQuestion = function() {
  //[...this.container.getElementsByClassName('guide2-input')].forEach(el => el.remove());
  this.currentNo += 1; // remove

  this.currentQuestion = this.questions.find(question => !question.answer);
  console.log('#cq:', this.currentQuestion);

  if (!this.currentQuestion) return this.endQuestion();

  if (this.skipQuestion()) {
    this.currentQuestion.answer = 'skip';
    return this.nextQuestion();
  }

  return this.renderQuestion();
};

Guide2_Form.prototype.skipQuestion = function() {
  for (const condition of this.currentQuestion.conditions) {
    // condition: skip, YES, NO
    if ([undefined].includes(condition.value)) continue;
    if (['YES', 'NO'].includes(condition.value)) return false;

    // condition: OR
    const result = this.results.find(c => c._id === condition._id);
    const answered = result.conditions.filter(c => c.value === 'OR' && c.answer === 'YES');
    if (answered.length === 0) {
      return false;
    }
  }
  return true; // skip
};

Guide2_Form.prototype.backQuestion = function() {
  var lastQuestion = this.answers.pop();

  this.currentNo = lastQuestion.no - 1; // remove
  this.nextQuestion();
};

Guide2_Form.prototype.endQuestion = function() {
  const ids = [];

  this.results.forEach(result => {
    let enabled = true;
    let orResults = [];
    for (const condition of result.conditions) {
      const question = this.questions.find(question => question._id === condition._id);

      console.log(question.name.slice(0, 5), question?.answer, '//', condition.value, condition._id);

      if (condition.value === 'YES') {
        if (['NO'].includes(question.answer)) {
          enabled = false;
          break;
        }
      } else if (condition.value === 'NO') {
        if (['YES'].includes(question.answer)) {
          enabled = false;
          break;
        }
      } else if (condition.value === 'OR') {
        orResults.push(question.answer)
      }
    };
    if (!enabled) return;

    if (orResults.length) {
      if (orResults.filter(r => r === 'YES').length === 0) return;
      if (orResults.filter(r => r === 'NO').length > 0) return;
    }

    console.log(' =>', enabled);
    ids.push(result._id);
  });

  // return console.log('#end');

  location.href = `${this.resultsUrl}?ids=${ids.join(',')}`;
};

Guide2_Form.prototype.renderQuestion = async function(items) {
  if (this.container.innerHTML) {
    this.container.style.visibility = 'hidden';
    const sleep = (time) => new Promise((r) => setTimeout(r, time));
    await sleep(200);
    this.container.style.visibility = 'visible';
  }

  var html = '<div class="question-header">';
  // html += `<p class="question-title"><span class="question-name">${question.question_name}</span>に関する質問です。</p>`;
  html += `<div class="question-name">${this.hbr(this.currentQuestion.name)}</div>`;
  html += '</div>'

  // html += '<div class="question-items">';
  // items.forEach(function(item) {
  //   html += '<div class="question-item">';
  //   html += self.renderInput(question, item);
  //   html += '</div>';
  // });
  html += '<div class="question-item">';
  html += this.renderInput();
  html += '</div>';

  html += '<div class="question-footer">';
  html += this.renderButtons(this.currentQuestion.type);
  html += '</div>';

  this.container.innerHTML = html;
  this.renderButtonsScript();
};

Guide2_Form.prototype.renderInput = function(_question, _item) {
  var html = '';

  html += `<input type="button" class="guide2-input yes" value="はい" data-question-id="${this.currentQuestion._id}" data-value="YES">`;
  html += ` <input type="button" class="guide2-input no" value="いいえ" data-question-id="${this.currentQuestion._id}" data-value="NO">`;

  return html;
};

Guide2_Form.prototype.renderButtons = function() {
  var html = '';

  if (this.currentNo) {
    html += '<input type="button" value="(未対応) 最初から" class="btn btn-init"> ';
  }
  if (this.currentNo) {
    html += '<input type="button" value="(未対応) 戻る" class="btn btn-back"> ';
  }
  // if (question_type) {
  //   html += '<input type="button" value="次へ" class="btn btn-next">';
  // }
  return html;
};

Guide2_Form.prototype.renderButtonsScript = function() {
  [...this.container.getElementsByClassName('guide2-input')].forEach(el => {
    el.addEventListener('click', el => {
      const value = el.target.dataset.value;
      this.questions.forEach(question => {
        if (question._id !== el.target.dataset.questionId) return;
        question.answer = value;

        question.conditions.forEach(condition => {
          const resultCondition = condition.result.conditions.find(r => r._id === question._id);
          if (resultCondition) resultCondition.answer = value;
        });
      });
      this.nextQuestion();
    });
  });

  // this.$el.find('.btn.btn-back').on('click', function() {
  //   self.backQuestion();
  // });
  // this.$el.find('.btn.btn-next').on('click', function() {
  //   self.saveAnswer();
  //   self.nextQuestion();
  // });

  [...this.container.getElementsByClassName('btn-init')].forEach(el => {
    el.addEventListener('click', () => {
      this.initQuestions();
    })
  });
};

Guide2_Form.prototype.hbr = function(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;")
    .replace(/\r?\n/g, '<br>');
};
