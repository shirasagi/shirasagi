document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector(".courses-list__search-form");
  if (!form) return;

  const params = new URLSearchParams(location.search);

  // select（単一値）
  form.querySelectorAll("select[name]").forEach(select => {
    const v = params.get(select.name);
    if (v !== null) select.value = v;
  });

  // checkbox（複数値）
  form.querySelectorAll('input[type="checkbox"][name]').forEach(cb => {
    const values = params.getAll(cb.name);
    if (values.length === 0) return;
    cb.checked = values.includes(cb.value);
  });

  // radio（単一値）
  form.querySelectorAll('input[type="radio"][name]').forEach(r => {
    const v = params.get(r.name);
    if (v !== null) r.checked = (v === r.value);
  });

  // 条件が全部空なら search/ ではなく一覧 park/attraction/ へ
  form.addEventListener("submit", (e) => {
    const fd = new FormData(form);

    // FormDataに値が入っているものだけ残す（空文字は捨てる）
    const hasAnyCondition = Array.from(fd.entries()).some(([name, value]) => {
      // select/radio の空文字だけ除外
      if (typeof value === "string") return value.trim() !== "";
      return true;
    });

    if (!hasAnyCondition) {
      e.preventDefault();
      location.href = "/courses/";
    }
  });
});
