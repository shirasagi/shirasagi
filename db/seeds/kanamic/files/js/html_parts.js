let basePath =  _commonjs.src.replace(/\/common\/.*/i,"/");
// フッターを読み込む
fetch(`${ basePath }common/html_parts/footer.html`)
  .then((response) => response.text())
  .then((html) => {

    // basePathを置換してリンクのパスを修正
    const footerHtml = html.replace(/{{ base_path }}/g, basePath);
    document.getElementById('html_parts_footer').innerHTML = footerHtml;
  })
  .catch((error) => {
    //console.error('Error loading footer:', error);
  });