Gm.Droparea = function() {

  var imageLoader;
  var maxImages = 5;

  function handleHtmlImageDrop(textHtml) {
    // Matches an <img src's url
    var matches = /src="([^"]+)"/g.exec(textHtml);
    if (matches.length > 0) {
      $.post('/comments/upload_img', {image_url: matches[1]}, function(data) {
        Gm.Droparea.attachImageToComment(data);
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
          Gm.Droparea.attachImageToComment(data);
        });
      };
    })(file);

    fileReader.readAsDataURL(file);
  };

  function initCanvas() {
    console.log('initCanvas');
    var canvas = $('.image-editor canvas')[0];
    var context = canvas.getContext("2d");
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.drawImage(imageLoader, 0, 0, imageLoader.width, imageLoader.height);
    saveImageReferences();
    $('.image-editor .image2').Jcrop({
      aspectRatio: 5,
      setSelect: [0, 0, 500, 100],
    });
  };

  function saveImageReferences() {
    var imageDataUrl = $('.image-editor canvas')[0].toDataURL("image/jpeg");
    $('.image-editor .image2')[0].src = imageDataUrl;
    var imageId = $('#dropped-files .selected')[0].id;
    $('#input' + imageId).val(imageDataUrl);
  }


  return {
    name: 'Droparea',

    /**
     * Triggered when an image is dropped into the droparea.
     */
    handleImageDrop: function(e) {
      e.originalEvent.preventDefault();
      e.originalEvent.stopPropagation();

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
      // TODO(slnc): here call custom fn when provided
      var curImage = $(this);
      var prevImage = $('#dropped-files .image2.selected');
      $('#dropped-files .image2').removeClass('selected');
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
        $('.image-editor .image2').css('max-width', imageLoader.width + 'px');
        $('.image-editor').show();

        initCanvas();
        // TODO(slnc): here call custom fn when provided
      };

      imageLoader.src = Gm.Droparea.getSelectedImageUrl();
    },

    getSelectedImageUrl: function() {
      var selectedImage = $('#dropped-files .selected');
      return selectedImage.
          css('background-image').replace('url(', '').replace(')', '').
          replace(/"/g, '');
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
      }).appendTo('.droparea').parentElement;

      if ($('#dropped-files > .image2').length < maxImages) {
        // Place the image inside the dropzone
        $('#dropped-files').append(
            '<div id="' + imageId + '" class="image2" style="background-image:' +
            ' url(' + image_url + ');">' +
            '<div class="image-deleter hidden">x</div></div>');
        // We unbind because we don't know how many of the existing images
        // might already have the function bound.
        $('#dropped-files .image2')
          .unbind('click', Gm.Droparea.EditImage)
          .bind('click', Gm.Droparea.EditImage)
          .unbind('mouseenter')
          .unbind('mouseleave')
          .bind('mouseenter', function() { $(this).find('.image-deleter').show(); })
          .bind('mouseleave', function() { $(this).find('.image-deleter').hide(); });

        $('#dropped-files .image-deleter').click(Gm.Droparea.removeImage);
      }
      else {
        Gm.showAlert(
            $('.comment-main-fields-area'),
            'No puedes añadir más de ' + maxImages + ' imágenes.');
      }
    },

    IgnoreDrag: function (e) {
      e.originalEvent.stopPropagation();
      e.originalEvent.preventDefault();
    },

    ContentInit: function() {
      if (Modernizr.draganddrop) {
        $('.droparea')
          .bind('dragenter', Gm.Droparea.IgnoreDrag)
          .bind('dragover', Gm.Droparea.IgnoreDrag)
          .bind('drop', this.handleImageDrop);
      } else {
        /*
         * TODO(slnc): disabled until we add a button to close the message and
         * store in a cookie and check that the user is actually logged in.
         *
        $('.pagelevel-feedback').html(
          'Tu navegador no soporta DragAndDrop por lo que algunas opciones se' +
          ' han deshabilitado. Navegadores que soportan DragAndDrop:' +
          ' Chrome 4.0+, Firefox 3.5+, Internet Explorer 10+, Opera 12.0+ y' +
          '  Safari 3.1+.').show();
          */
      }
    },

    FullPageInit: function() {
      $.event.props.push('dataTransfer');
      $.event.props.push('drop');
      this.ContentInit();
    },
  };  // return
}();

Gm.registerModule(Gm.Droparea);
