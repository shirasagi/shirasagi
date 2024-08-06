import {Controller} from "@hotwired/stimulus"
import {smoothDnD} from 'smooth-dnd';
import {dispatchEvent, objecToUrlSafeBase64, urlSafeBase64ToObject} from "../../../ss/tool";
import Dialog from "../../../ss/dialog";
import ejs from 'ejs/ejs';

const DEFAULT_OVERALL_OPERATOR = "all";
const DEFAULT_INDIVIDUAL_OPERATOR = "all";

function buildExpr(operatorElement, { categories, expressions }) {
  const operatorName = operatorElement.closest("label").textContent.trim();
  const expr_template = `
      <span class="gws-category-expr gws-category-expr-term">
        <span class="gws-category-expr gws-category-expr-op" data-op="<%= op.code %>"><%= op.name %></span>
        <% if (categories) { %>
          <% categories.forEach(function(cate) { %>
            <span class="gws-category-label gws-category-expr gws-category-expr-sym" style="<%= cate.style %>">
              <span><%= cate.trailing_name %></span>
            </span>
          <% }); %>
        <% } %>
        <% if (expressions) { %>
          <% expressions.forEach(function(expression) { %>
            (<%- expression %>)
          <% }); %>
        <% } %>
      </span>
    `;

  return ejs.render(expr_template, { op: { name: operatorName, code: operatorElement.value }, categories: categories, expressions: expressions });
}

export default class extends Controller {
  static values = {
    url: String
  };

  seq = 0;

  connect() {
    this.element.addEventListener("click", (ev) => {
      if ("name" in ev.target) {
        if (ev.target.name === "btn-add-individual-criteria") {
          this.#addIndividualCriteria();
        }
        if (ev.target.name === "btn-delete-individual-criteria") {
          this.#deleteIndividualCriteria(ev.target);
        }
        if (ev.target.name === "btn-open-category-dialog") {
          this.#openCategoryDialog(ev.target);
        }
        if (ev.target.name === "btn-delete-category") {
          this.#deleteCategory(ev.target);
        }
      }
      if ("classList" in ev.target && ev.target.classList.contains("btn-open-category-dialog")) {
        this.#openCategoryDialog(ev.target);
        ev.preventDefault();
        return false;
      }
      if (ev.target.closest('[name="btn-delete-category"]')) {
        this.#deleteCategory(ev.target);
      }
    })
    this.element.addEventListener("change", (ev) => {
      if ("name" in ev.target) {
        if (ev.target.name === "overall_op") {
          this.#updateReturnPath();
        }
      }
      if ("classList" in ev.target && ev.target.classList.contains("individual-criteria-operator")) {
        this.#updateIndividualOp(ev.target);
        this.#updateReturnPath();
      }
    })
    this.#restartSmoothDnD();
    this.#updateReturnPath();
  }

  get #individualCriteriaFormTemplate() {
    if (this._individualCriteriaFormTemplate) {
      return this._individualCriteriaFormTemplate;
    }

    this._individualCriteriaFormTemplate = this.element.querySelector("[data-name='individual-criteria-form']");
    return this._individualCriteriaFormTemplate;
  }

  get #categoryTemplate() {
    if (this._categoryTemplate) {
      return this._categoryTemplate;
    }

    this._categoryTemplate = this.element.querySelector("[data-name='category']");
    return this._categoryTemplate;
  }

  get #individualCriteriaContainer() {
    if (this._individualCriteriaContainer) {
      return this._individualCriteriaContainer;
    }

    this._individualCriteriaContainer = this.element.querySelector(".individual-criteria-container");
    return this._individualCriteriaContainer;
  }

  #restartSmoothDnD() {
    if (this.sdnd) {
      this.sdnd.dispose()
      this.sdnd = null

      requestAnimationFrame(() => this.#restartSmoothDnD())
      return
    }

    this.sdnd = smoothDnD(
      this.element.querySelector(".individual-criteria-container"),
      {
        lockAxis: "y", dragHandleSelector: ".individual-criteria-handler",
        onDrop: () => { this.#restoreIndividualCriteriaOperator(); this.#updateReturnPath() }
      })
  }

  #disposeSmoothDnD() {
    if (!this.sdnd) {
      return;
    }

    this.sdnd.dispose();
    this.sdnd = null;
  }

  #updateIndividualOp(element) {
    const formElement = element.closest(".individual-criteria");

    const individualOperatorElements = formElement.querySelectorAll(".individual-criteria-operator");
    const individualOperatorElement = Array.from(individualOperatorElements).find((element) => element.checked);
    const individualOperator = individualOperatorElement ? individualOperatorElement.value : DEFAULT_INDIVIDUAL_OPERATOR;

    formElement.querySelector('[name="individual_op"]').value = individualOperator;
  }

  // smoothDnd を用いてドロップすると、ラジオボタンの選択が解除されてしまう。
  // そこで、事前にラジオボタンの選択をhiddenへ格納しておき、ドロップされた際にhiddenから復元する。
  #restoreIndividualCriteriaOperator() {
    const individualCriteriaElements = this.element.querySelectorAll(".individual-criteria");
    individualCriteriaElements.forEach((individualCriteriaElement) => {
      const individualOperator = individualCriteriaElement.querySelector('[name="individual_op"]').value || DEFAULT_INDIVIDUAL_OPERATOR;

      const individualOperatorElements = individualCriteriaElement.querySelectorAll(".individual-criteria-operator");
      const individualOperatorElement = Array.from(individualOperatorElements).find((element) => element.value === individualOperator);
      individualOperatorElement.checked = true;
    });
  }

  #updateReturnPath() {
    const individualFilters = []
    const individualFilterExprs = []
    const individualCriteriaElements = this.element.querySelectorAll(".individual-criteria");
    individualCriteriaElements.forEach((individualCriteriaElement) => {
      const { op, categories, expr } = this.#buildFilter(individualCriteriaElement);
      individualFilters.push({ op, categories });
      individualFilterExprs.push(expr);
    });

    const overallCriteriaElement = this.element.querySelector(".overall-criteria");
    const overallOperatorElements = overallCriteriaElement.querySelectorAll("[name='overall_op']");
    const overallOperatorElement = Array.from(overallOperatorElements).find((element) => element.checked);
    const overallOperator = overallOperatorElement ? overallOperatorElement.value : DEFAULT_OVERALL_OPERATOR;

    const base64Filter = objecToUrlSafeBase64({ op: overallOperator, filters: individualFilters }, { padding: false });
    const base64FilterElement = this.element.querySelector('[name="base64_filter"]');
    if (base64FilterElement) {
      base64FilterElement.value = base64Filter;
    }

    if (this.urlValue) {
      const returnPath = this.urlValue.replaceAll("$(category_id)", base64Filter).replaceAll("%24%28category_id%29", base64Filter);
      const returnPathElement = this.element.querySelector('[name="return_path"]');
      if (returnPathElement) {
        returnPathElement.value = returnPath;
      }
    }

    const filterExprElement = this.element.querySelector('[name="filter_expr"]');
    if (filterExprElement) {
      const exprHtml = buildExpr(overallOperatorElement, { expressions: individualFilterExprs });
      // filterExprElement.value = objecToUrlSafeBase64({ html: exprHtml });
      filterExprElement.value = exprHtml;
    }
  }

  #buildFilter(individualCriteriaElement) {
    const categories = [];
    const categoryIds = [];
    individualCriteriaElement.querySelectorAll("[name='s[category_ids][]']").forEach((element) => {
      const cate = urlSafeBase64ToObject(element.value);
      categories.push(cate);
      categoryIds.push(cate.id);
    })

    const individualOperatorElements = individualCriteriaElement.querySelectorAll(".individual-criteria-operator");
    const individualOperatorElement = Array.from(individualOperatorElements).find((element) => element.checked);
    const individualOperator = individualOperatorElement ? individualOperatorElement.value : DEFAULT_INDIVIDUAL_OPERATOR;

    return { op: individualOperator, categories: categoryIds, expr: buildExpr(individualOperatorElement, { categories: categories }) }
  }

  #addIndividualCriteria() {
    this.#disposeSmoothDnD();

    const cloneElement = this.#individualCriteriaFormTemplate.content.cloneNode(true);

    const newName = `individual_${new Date().getTime()}_${this.seq}`;
    this.seq += 1;
    cloneElement.querySelectorAll('.individual-criteria-operator').forEach((element) => element.name = newName);

    this.#individualCriteriaContainer.appendChild(cloneElement);
    this.#updateReturnPath();
    this.#restartSmoothDnD();

    dispatchEvent(this.element, "ss:individualCriteriaAdded");
  }

  #deleteIndividualCriteria(btnElement) {
    this.#disposeSmoothDnD();

    const formElement = btnElement.closest(".individual-criteria");
    formElement.remove();
    this.#updateReturnPath();
    this.#restartSmoothDnD();

    dispatchEvent(this.element, "ss:individualCriteriaDeleted");
  }

  #openCategoryDialog(anchorElement) {
    const formElement = anchorElement.closest(".individual-criteria");
    const { op, categories } = this.#buildFilter(formElement);
    const filterString = categories.length ? objecToUrlSafeBase64({ op, categories }, { padding: false }) : "-";
    const path = anchorElement.href.replace("$(category_id)", filterString).replace("%24%28category_id%29", filterString);

    Dialog.showModal(path).then((result) => this.#applySelectedCategories(formElement, result));
  }

  #applySelectedCategories(formElement, dialog) {
    if (!dialog.returnValue) {
      // dialog is just closed
      return;
    }

    const categories = [];
    dialog.returnValue.forEach((value) => {
      if (value[0] === 's[category_ids][]') {
        const cate = urlSafeBase64ToObject(value[1]);
        categories.push(cate);
      }
    });

    // delete all
    formElement.querySelectorAll(".category-item-wrap").forEach((element) => element.remove());

    // and insert
    categories.forEach((cate) => {
      const newCategoryElement = this.#categoryTemplate.content.firstElementChild.cloneNode(true);
      newCategoryElement.dataset.id = cate.id;
      newCategoryElement.style = cate.style;
      newCategoryElement.querySelector("span").innerText = cate.name;
      newCategoryElement.querySelector("[name='s[category_ids][]']").value = objecToUrlSafeBase64(cate, { padding: false });

      formElement.querySelector(".btn-open-category-dialog").before(newCategoryElement);
    })
    this.#updateReturnPath();
  }

  #deleteCategory(btnElement) {
    const categoryElement = btnElement.closest(".category-item-wrap");
    categoryElement.remove();
    this.#updateReturnPath();
    dispatchEvent(this.element, "ss:categoryDeleted");
  }
}
