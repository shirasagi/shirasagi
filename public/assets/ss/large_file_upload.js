function SS_Large_File_Upload($el, urls) {
  this.$el = $el;

  this.render(urls);
}

SS_Large_File_Upload.prototype.render = function (urls) {
  this.$el.on('click', () => {
    $(".main-box .import-button").prop("disabled", true);
    $('.progress dd').empty();
    appendLoadingWrapper();
    importFiles();
  });

  $('#file-picker').on('change', () => {
    $(".main-box .import-button").prop("disabled", false);
  })

  const importFiles = () => {
    let allFiles = document.getElementById("file-picker").files;
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

    let filenamesFormData = new FormData();
    let filesFormData = new FormData();
    let selectedFilenames = setFilenames(arrayFiles, filenamesFormData);
    let selectedFiles = setFiles(arrayFiles, filesFormData);

    fetch(urls['initUrl'], {
      method: "POST",
      body: selectedFilenames,
    })
      .then((response) => response.json())
      .then((data) => {
        let promises = [];
        let formData = new FormData();
        let resFiles = JSON.stringify(data["files"]);
        appendFileList();
        appendExcludedFiles(data["excluded_files"]);

        selectedFiles.forEach((file) => {
          if( !data["files"][file.name] ){ return; }

          let promise = sendFile(file);
          formData.append("files", resFiles);
          formData.append("cur_site_id", data["cur_site_id"]);
          promises.push(promise);
        });

        Promise.all(promises).then(() => {
          fetch(urls['finalizeUrl'], {
            method: "PUT",
            body: formData,
          })
            .then((response) => {
              $(".loading-img").remove();
              $(".waiting-text").text("アップロードが完了しました");
            })
            .catch((err) => {
              console.log(err);
            });
        });
      })
      .catch((err) => {
        console.log(err);
      });
  }

  const appendLoadingWrapper = () => {
    let $loadingWrapper = $("<div/>").attr({
      class: "loading-wrapper",
    });
    let $loadingImg = $("<img/>").attr({
      src: "/assets/img/loading.gif",
      class: "loading-img",
    });
    let $waitingText = $("<p/>")
      .text("アップロードが完了するまでお待ちください。")
      .attr({ class: "waiting-text d-inline-block" });

    $(".progress dd").append($loadingWrapper);
    $($loadingWrapper).append($waitingText);
    $($loadingWrapper).append($loadingImg);
  };

  const appendExcludedFiles = (excludedFilesAry) => {
    let excludedFiles = excludedFilesAry.join("・");
    let $excludedFilesWrapper = $("<div/>").attr({
      class: "excluded-files-wrapper",
    });
    let $alertP = $("<p/>")
      .attr("class", "mt-2")
      .text(
      `以下のファイルは許可された拡張子ではないため、アップロードできませんでした。`
    );
    let $excludedFilesP = $("<p/>").text(excludedFiles);

    $(".progress dd").append($excludedFilesWrapper);
    $($excludedFilesWrapper).append($alertP);
    $($excludedFilesWrapper).append($excludedFilesP);
  };

  const setFilenames = (files, filenamesFormData) => {
    files.forEach((file) => {
      filenamesFormData.append("filenames[]", file.name);
    });

    return filenamesFormData;
  };

  const setFiles = (files, filesFormData) => {
    files.forEach((file, i) => {
      filesFormData.append("files[]", files[i], files[i].name);
    });

    return filesFormData;
  };

  const appendFileList = () => {
    let $fileList = $("<ol />").attr("class", "file-list");
    $(".progress dd").prepend($fileList);
  };

  const sendFile = async (file) => {
    let chunkSize = 1024 * 1024; //1MBずつ
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

      await fetch_retry({
        createUrl: urls['createUrl'],
        formData: formData,
        numRetry: 5,
        numChunk: numChunk,
        totalChunks: totalChunks,
        filename: file.name
      }
      ).catch((err) => {
        console.log(err);
      });
    }
  };

  const fetch_retry = (data) => {
    return fetch(data["createUrl"], {
      method: 'POST',
      body: data["formData"],
    })
      .then((res) => {
        if (res.ok) {
          updateProgress(data["numChunk"], data["totalChunks"], data["filename"]);
        }
      })
      .catch((err) => {
        if (numRetry === 0) throw err;

        data["numRetry"] -= 1;
        return fetch_retry(data);
      });
  };

  const updateProgress = (numChunk, totalChunks, filename) => {
    let progressRate = Math.ceil((100 * numChunk) / totalChunks).toString();
    let fileWithoutExtension = getFileWithoutExtension(filename);

    if ($(".file-list li").hasClass(fileWithoutExtension)) {
      $(`.file-list li.${fileWithoutExtension} progress`).attr("value", progressRate);
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
      $(".progress .file-list").append($newFileWrapper);
      showCompletedStatus(filename, progressRate);
    }
  };

  const showCompletedStatus = (filename, progressRate) => {
    let fileWithoutExtension = getFileWithoutExtension(filename);
    if (progressRate !== "100") { return; }
    if ($(`.file-list .completed-${fileWithoutExtension}`).length) { return; }

    let $completedTag = $("<span />")
      .text("完了")
      .attr("class", `completed-${fileWithoutExtension} ml-1`)
      .attr("style", "width: 30px")
    $(`li.${fileWithoutExtension}`).append($completedTag);
  };

  const getFileWithoutExtension = (filename) => {
    return filename.replace(/\.[^/.]+$/, "");
  };
}
