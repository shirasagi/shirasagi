function Cms_Large_File($el, initUrl, createUrl, finalizeUrl, deleteInitFilesUrl) {
  this.$el = $el;

  this.render(initUrl, createUrl, finalizeUrl, deleteInitFilesUrl);
}

Cms_Large_File.prototype.render = function (initUrl, createUrl, finalizeUrl, deleteInitFilesUrl) {
  this.$el.on('click', () => {
    $('.import-button').prop('disabled', true);
    $('.progress dd').empty();
    showLoadingImg();
    importFiles();
  });

  $('#file-picker').on('change', () => {
    $('.import-button').prop('disabled', false);
  })

  const importFiles = () => {
    let allFiles = document.getElementById('file-picker').files;
    let arrayFiles = Array.from(allFiles);

    arrayFiles.sort((a, b) => {
      let nameA = a.name.toUpperCase();
      let nameB = b.name.toUpperCase();
      if (nameA < nameB) {
        return -1;
      }
      if (nameA > nameB) {
        return 1;
      }

      return 0;
    });

    let FilenamesFormData = new FormData();
    let FilesFormData = new FormData();
    let selectedFilenames = setFilenames(arrayFiles, FilenamesFormData);
    let selectedFiles = setFiles(arrayFiles, FilesFormData);

    fetch(initUrl, {
      method: "POST",
      body: selectedFilenames,
    })
      .then((response) => response.json())
      .then((data) => {
        appendProgressBarWrapper();

        let promises = [];
        let formData = new FormData();
        resFiles = JSON.stringify(data["files"]);
        selectedFiles.forEach((file) => {
          if( !data["files"][file.name] ){ return; }

          let promise = sendFile(file);
          formData.append("files", resFiles);
          formData.append("cur_site_id", data["cur_site_id"]);
          promises.push(promise);
        });

        Promise.all(promises).then(() => {
          fetch(finalizeUrl, {
            method: "PUT",
            body: formData,
          })
            .then((response) => response.json())
            .catch((err) => {
              console.log(err);
            });
        });
      })
      .catch((err) => {
        console.log(err);
      });
  }

  const showLoadingImg = () => {
    let $loadingImg = $('<img/>').attr({
      src: '/assets/img/loading.gif',
      class: 'loading-img',
    });

    $('.progress dd').append($loadingImg);
  };

  const setFilenames = (files, FilenamesFormData) => {
    files.forEach((file) => {
      FilenamesFormData.append("filenames[]", file.name);
    });

    return FilenamesFormData;
  };

  const setFiles = (files, FilesFormData) => {
    files.forEach((file, i) => {
      FilesFormData.append("files[]", files[i], files[i].name);
    });

    return FilesFormData;
  };

  const appendProgressBarWrapper = () => {
    let $progressBarWrapper = $("<div />").attr("class", "progress-bar mt-4");
    $(".progress dd").append($progressBarWrapper);

    let $fileList = $("<ol />").attr("class", "file-list");
    $(".progress dd").append($fileList);
  };

  const sendFile = async (file) => {
    chunkSize = 1024 * 1024; //1MBずつ
    let totalChunks = Math.ceil(file.size / chunkSize);

    for (let i = 0; i < totalChunks; i++) {
      let start = i * chunkSize;
      let stop = start + chunkSize;
      let blob = file.slice(start, stop);
      let numChunk = i + 1;

      const formData = new FormData();
      formData.append(
        'blob',
        new Blob([blob], { type: 'application/octet-stream' })
      );
      formData.append('filename', file.name);

      await fetch_retry(createUrl, formData, 5, numChunk, totalChunks, file.name).catch((err) => {console.log(err);});
    }
  };

  const fetch_retry = (createUrl, formData, numRetry, numChunk, totalChunks, filename) => {
    return fetch(createUrl, {
      method: 'POST',
      body: formData,
    })
      .then((res) => {
        if (res.ok) {
          $('.loading-img').remove();
          updateProgress(numChunk, totalChunks, filename);
        }
      })
      .catch((err) => {
        if (numRetry === 1) throw err;
        return fetch_retry(createUrl, formData, numRetry - 1);
      });
  };

  const updateProgress = (numChunk, totalChunks, filename) => {
    progressRate = Math.ceil((100 * numChunk) / totalChunks).toString();
    fileWithoutExtension = getFileWithoutExtension(filename);

    if ($("li").hasClass(fileWithoutExtension)) {
      $(`li.${fileWithoutExtension} progress`).attr("value", progressRate);

      showCompletedStatus(filename, progressRate);
    } else {
      let $newFileWrapper = $("<li />").attr("class", fileWithoutExtension);
      let $newLabel = $("<label />").text(filename).attr({
        for: "file",
        class: "mr-4",
      });
      let $newProgress = $("<progress />").attr({
        max: "100",
        value: progressRate,
      });
      $newFileWrapper.append($newLabel);
      $newFileWrapper.append($newProgress);
      $(".file-list").append($newFileWrapper);
      showCompletedStatus(filename, progressRate);
    }
  };

  const showCompletedStatus = (filename, progressRate) => {
    let fileWithoutExtension = getFileWithoutExtension(filename);
    if (progressRate !== "100") { return; }
    console.log('aaaaa')
    if ($(`.completed-${fileWithoutExtension}`).length) { return; }

    let $completedTag = $("<span />")
      .text("完了")
      .attr("class", `completed-${fileWithoutExtension}`);
    $(`li.${fileWithoutExtension}`).append($completedTag);
  };

  const removeDisplayedFiles = () => {
    $('.loading-img').remove();
    $('.count-files').remove();
  };

  const deleteInitFiles = () => {
    fetch(deleteInitFilesUrl, {
      method: 'DELETE',
    }).then((res) => {
      $('.import-button').prop('disabled', false);
    });
  };

  const showNoDateTxtError = (data) => {
    let $noBidDateTxtP = $('<p/>')
      .attr({
        class: 'mb-2',
        style: 'color: red;',
      })
      .text(data['no_bid_date_txt']);
    $('.progress dd').append($noBidDateTxtP);
  };

  const createSelectTag = (nodeOptions) => {
    $newSelect = $('<select>').attr({ class: 'node-select mr-2' });

    if (nodeOptions?.length) {
      $newSelect.append('<option disabled selected value>取り込み先を選択してください</option>');
      nodeOptions.forEach((option) => {
        $newSelect.append(`<option value=\'${option[0]}\'>${option[1]}</option>`);
      });
      $newButton = createSubmitButton(true);
    } else {
      $p = $('<p />').
        text('※インポートされた開札日を設定しているフォルダが無ければ、新規フォルダのみ選択できます。').
        attr('style', 'color: red;')
      $('.job-wrapper').append($p)

      setJobField('new');
      $newButton = createSubmitButton(false);
    }

    $newSelect.append(`<option value=\'new\'>新規フォルダ</option>`);
    $($newJobWrapper).append($newSelect);
    $($newJobWrapper).append($newButton);
  }

  const setJobField = (targetNode) => {
    let selectedBidNode;
    if (targetNode === 'new') {
      selectedBidNode = targetNode;
    } else {
      selectedBidNode = $('.node-select option:selected').val();
    }
    let bidDate = $('.bid-date.hide').text();
    let numZip = $('.file-list li').length;
    let categoryName = $('.category-name').text();

    $hiddenField1 = $('<input />').attr({
      type: 'hidden',
      name: 'selectedBidNode',
      value: selectedBidNode,
    });

    $hiddenField2 = $('<input />').attr({
      type: 'hidden',
      name: 'bidDate',
      value: bidDate,
    });

    $hiddenField3 = $('<input />').attr({
      type: 'hidden',
      name: 'numZip',
      value: numZip,
    });

    $hiddenField4 = $('<input />').attr({
      type: 'hidden',
      name: 'categoryName',
      value: categoryName,
    });

    $($newJobWrapper).append($hiddenField1);
    $($newJobWrapper).append($hiddenField2);
    $($newJobWrapper).append($hiddenField3);
    $($newJobWrapper).append($hiddenField4);
  };

  const createSubmitButton = (boolean) => {
    $newButton = $('<input />').attr({
      type: 'submit',
      value: '取り込み開始',
      class: 'mt-2 job-start-btn',
      disabled: boolean
    });

    return $newButton
  }

  const getFileWithoutExtension = (filename) => {
    return filename.replace(/\.[^/.]+$/, "");
  };
}
