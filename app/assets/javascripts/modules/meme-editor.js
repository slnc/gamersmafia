Gm.MemeEditor = function() {

  var imageLoader;
  var generateMemeTimer;
  // Stores per-meme lines.
  var memeLines = {};
  var generateMemeKeyUpDelayMillis = 500;
  var maxImages = 5;

  function drawMemeText() {
    var context = $('.image-editor canvas')[0].getContext("2d");
    var memeMetrics = getDrawingInfo();

    memeMetrics.yPos = memeMetrics.yPosTop;
    Gm.MemeEditor.drawTextBlock(context, $('.meme_top').val(), memeMetrics);

    memeMetrics.yPos = memeMetrics.yPosMiddle;
    Gm.MemeEditor.drawTextBlock(context, $('.meme_middle').val(), memeMetrics);

    memeMetrics.yPos = memeMetrics.yPosBottom;
    Gm.MemeEditor.drawTextBlock(context, $('.meme_bottom').val(), memeMetrics);
  };

  function handleHtmlImageDrop(textHtml) {
    // Matches an <img src's url
    var matches = /src="([^"]+)"/g.exec(textHtml);
    if (matches.length > 0) {
      $.post('/comments/upload_img', {image_url: matches[1]}, function(data) {
        Gm.MemeEditor.attachImageToComment(data);
      });
    }
  };

  function handleFileImageDrop(file) {
    if (!file.type.match('image.*')) {
      // TODO(slnc): feedback
      return false;
    }

    var fileReader = new FileReader();
    fileReader.onload = (function(f) {
      return function(e) {
        // TODO(slnc): respect in some way the image name
        // var fileName = f.name;
        $.post('/comments/upload_img', {image: this.result}, function(data) {
          Gm.MemeEditor.attachImageToComment(data);
        });
      };
    })(file);

    fileReader.readAsDataURL(file);
  };

  function initCanvas() {
    var canvas = $('.image-editor canvas')[0];
    var context = canvas.getContext("2d");
    context.clearRect(0, 0, canvas.width, canvas.height);

    context.drawImage(imageLoader, 0, 0, imageLoader.width, imageLoader.height);
  };

  function splitTextInLines(text, context, maxWidth) {
    var words = text.split(" ");
    var lines = [];
    var line = "";
    for (var n = 0; n < words.length; n++) {
      var testLine = line + words[n] + " ";
      var metrics = context.measureText(testLine);
      if (metrics.width > maxWidth) {
        lines.push(line);
        line = words[n] + " ";
      }
      else {
        line = testLine;
      }
    }
    lines.push(line);
    while (lines.length > 2) {
      lines.pop();
    }
    return lines;
  };

  /**
   * Returns font sizes and coordinates to draw in as an object.
   */
  function getDrawingInfo() {
    return {
      'fontSizeBig': Math.round(imageLoader.height * (150 / 1000)),
      'fontSizeSmall': Math.round(imageLoader.height * (100 / 1000)),
      'lineHeightSmall': Math.round(imageLoader.height * (100 / 1000) * 1.1),

      // Maximum width of any text line in the meme
      'maxWidth': Math.round(imageLoader.width * 0.96),

      // xPos text will be drawn center-aligned around this point
      'xPos': Math.round(imageLoader.width / 2),

      // This attribute will hold yPosTop, yPosMiddle and yPosBottom at
      // different times.
      'yPos': 0,

      'yPosTop': Math.round(imageLoader.height * 200 / 1000),
      'yPosMiddle': Math.round(imageLoader.height * 540 / 1000),
      'yPosBottom': Math.round(imageLoader.height * 915 / 1000),
    };
  };

  function updateMemeImageReferences() {
    var imageDataUrl = $('.image-editor canvas')[0].toDataURL("image/jpeg");
    $('.image-editor .image')[0].src = imageDataUrl;
    var imageId = $('#dropped-files .selected')[0].id;
    $('#input' + imageId).val(imageDataUrl);
  }


  return {
    name: 'MemeEditor',

    /**
     * Triggered when an image is dropped into the droparea.
     */
    handleImageDrop: function(e) {
      e.originalEvent.preventDefault();

      var textHtml = e.dataTransfer.getData("text/html");
      if (textHtml != undefined && textHtml != '') {
        handleHtmlImageDrop(textHtml);
        return;
      }

      $.each(e.dataTransfer.files, function(index, file) {
        handleFileImageDrop(file);
      });
    },

    /**
     * Called when an image has been clicked to enter Meme edit mode.
     */
    EditImage: function(e) {
      $('.image-editor').hide();
      $('.meme_top').val('');
      $('.meme_middle').val('');
      $('.meme_bottom').val('');
      var curImage = $(this);
      var prevImage = $('#dropped-files .image.selected');
      $('#dropped-files .image').removeClass('selected');
      if (prevImage.length > 0 && this.id == prevImage[0].id) {
        // De-selecting image
        return;
      }
      curImage.addClass('selected');

      imageLoader = new Image();
      imageLoader.onload = function() {
        var canvas = $('.image-editor canvas')[0];
        canvas.width = imageLoader.width;
        canvas.height = imageLoader.height;
        $('.image-editor .image').css('max-width', imageLoader.width + 'px');
        $('.image-editor').show();

        Gm.MemeEditor.generateMeme();
      };

      imageLoader.src = Gm.MemeEditor.getSelectedImageUrl();
      Gm.MemeEditor.restoreMemeLines();
    },

    getSelectedImageUrl: function() {
      var selectedImage = $('#dropped-files .selected');
      return selectedImage.
          css('background-image').replace('url(', '').replace(')', '');
    },

    /**
     * Sets up a timeout function that will regenerate a meme after a line has
     * been drawn.
     */
    setupGenerateMemeTimer: function() {
      if (generateMemeTimer != undefined) {
        clearInterval(generateMemeTimer);
      }

      Gm.MemeEditor.saveMemeLines();
      generateMemeTimer = setTimeout(
          Gm.MemeEditor.generateMeme, generateMemeKeyUpDelayMillis);
    },

    /**
     * Draws a block of text on the meme. If the text is too long it will split
     * it into lines and make sure that the text doesn't take more space than a
     * given size.
     */
    drawTextBlock: function(context, text, memeMetrics) {
      context.fillStyle = "#ffffff";
      context.shadowColor = "#000";
      context.textAlign = 'center';
      context.font = "bold " + memeMetrics.fontSizeBig + "px Impact";
      var metrics = context.measureText(text);

      if (metrics.width <= memeMetrics.maxWidth) {
        // Text fits in one line
        context.font = "bold " + memeMetrics.fontSizeBig + "px Impact";
        context.shadowBlur = Math.round(memeMetrics.fontSizeBig / 3);
        context.fillText(text, memeMetrics.xPos, memeMetrics.yPos);
      } else {
        // Text doesn't fit in one line. We fill the first line with the smaller
        // font size we add as many words to the second line as possible to not
        // go past the line limit.
        context.font = "bold " + memeMetrics.fontSizeSmall + "px Impact";
        context.shadowBlur = Math.round(memeMetrics.fontSizeSmall / 3);

        var words = text.split(" ");
        var line = "";
        var lines = splitTextInLines(text, context, memeMetrics.maxWidth);
        var yPos = memeMetrics.yPos - Math.round(memeMetrics.fontSizeBig / 2);

        var canvas = $('.image-editor canvas')[0];
        for (var n = 0; n < lines.length; n++) {
          context.fillText(lines[n], memeMetrics.xPos, yPos);
          yPos += memeMetrics.lineHeightSmall;
          if (yPos > canvas.height) {
            // Too much text. We just don't draw it and assume that the user
            // will write a shorter sentence.
            break;
          }
        }  // for
      }  // else
    },

    saveMemeLines: function() {
      var imageId = $('#dropped-files .selected')[0].id;
      memeLines[imageId] = {
        'top': $('.meme_top').val(),
        'middle': $('.meme_middle').val(),
        'bottom': $('.meme_bottom').val(),
      };
    },

    restoreMemeLines: function() {
      var imageId = $('#dropped-files .selected')[0].id;
      if (memeLines[imageId] == undefined) {
        return;
      }

      $('.meme_top').val(memeLines[imageId].top);
      $('.meme_middle').val(memeLines[imageId].middle);
      $('.meme_bottom').val(memeLines[imageId].bottom);
    },

    generateMeme: function() {
      initCanvas();
      drawMemeText();
      Gm.MemeEditor.saveMemeLines();
      updateMemeImageReferences();
    },

    removeImage: function(e) {
      e.stopPropagation();
      var curImage = e.currentTarget.parentElement;
      if ($(curImage).hasClass('selected')) {
        $('.image-editor').hide();
      }
      $('#input' + curImage.id).remove();
      $('#' + curImage.id).remove();
    },

    attachImageToComment: function(image_url) {
      var imageId = (
          'comment_image_' + image_url + Math.round(Math.random() * 1000000));
      imageId = imageId
        .replace(/\//g, '-').replace(/[.]/g, '-').replace(/\n/g, '');

      $('<input>').attr({
        type: 'hidden',
        id: 'input' + imageId,
        name: 'images[]',
        value: image_url,
      }).appendTo('#new_comment');

      if ($('#dropped-files > .image').length < maxImages) {
        // Place the image inside the dropzone
        $('#dropped-files').append(
            '<div id="' + imageId + '" class="image" style="background-image:' +
            ' url(' + image_url + ');">' +
            '<div class="image-deleter hidden">x</div></div>');
        // We unbind because we don't know how many of the existing images
        // might already have the function bound.
        $('#dropped-files .image')
          .unbind('click', Gm.MemeEditor.EditImage)
          .bind('click', Gm.MemeEditor.EditImage)
          .unbind('mouseenter')
          .unbind('mouseleave')
          .bind('mouseenter', function() { $(this).find('.image-deleter').show(); })
          .bind('mouseleave', function() { $(this).find('.image-deleter').hide(); });

        $('#dropped-files .image-deleter').click(Gm.MemeEditor.removeImage);
      }
      else {
        Gm.showAlert(
            $('.comment-main-fields-area'),
            'No puedes añadir más de ' + maxImages + ' imágenes.');
      }
    },

    ContentInit: function() {
      $('.comments .droparea').bind('drop', this.handleImageDrop);
      $('.meme_top').keyup(Gm.MemeEditor.setupGenerateMemeTimer);
      $('.meme_middle').keyup(Gm.MemeEditor.setupGenerateMemeTimer);
      $('.meme_bottom').keyup(Gm.MemeEditor.setupGenerateMemeTimer);
    },

    FullPageInit: function() {
      $.event.props.push('dataTransfer');
      this.ContentInit();
    },
  };  // return
}();

Gm.registerModule(Gm.MemeEditor);
