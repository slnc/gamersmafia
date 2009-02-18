// wsEditor 1.3
// author: Juan Alonso <s@slnc.me>
// Copyright Juan Alonso <s@slnc.me> - All rights reserved

var wsEditor = function (field_id, width, height, css)
{
    this.options = arguments;
    this.create();
}


// constructor
function wsEditor () 
{
/*
   arguments[0]: field_id << where we take the content
   arguments[1]: width
   arguments[2]: height
   arguments[3]: css
*/

  // arguments[0]: field_id
  // attach object methods

  // by default create a new editor
  this.options = arguments;
  this.create();
}


// create editor object
wsEditor.prototype.create = function ()
{
  /*
    options(name, contents, width, height, css for the wysiwyg, url for insert_img popup)
   */
  var defaultOptions = new Array('_auto', '', '500px', '400px', 'wsEditor.css', '');

  this.resolve_name();
  this.generate_toolbar();
  document.write('<div class="wsEditor">');
  this.generate_edit_box();
  this.generate_mode_switcher();
  document.write('</div>');
  this.init();

  if (!(is_ie || is_opera) && !is_gecko)
    wsEditorSwitchMode(this.id, 'code');
}


// resolve editor's Id
wsEditor.prototype.resolve_name = function ()
{
  // get new editor Id
  var sBase    = 'wsEditor';
  var sCounter = 0;
  var sName    = sBase + sCounter;

  if (this.options[0] == '_auto') // name given
  {
    // generate name
    while (document.getElementById(sName))
      sName = sBase + (sCounter + 1);

    sOriginalName = sName;

  }
  else
  {
    sOriginalName = this.options[0];
    sName         = this.options[0];
  }

  if (document.getElementById(sName))
  {
    sBase = this.options[0];

    while (document.getElementById(sName))
      sName = sBase + (sCounter + 1);
  }

  this.id           = sName;
  this.originalName = sOriginalName;
  this.idTa         = sName+'Ta';
  this.idIf         = sName+'If';
}


// generate upper buttons area
wsEditor.prototype.generate_toolbar = function () 
{
  var actions = new Array('undo', 'redo', 'cut', 'copy', 'paste', 'bold', 'italic', 'indent', 'outdent', 'createLink', 'insertImage', 'justifyLeft', 'justifyCenter', 'justifyRight', 'InsertUnorderedList', 'clean');

  document.write('<div class="wsEditorToolbar" id="'+this.id+'Toolbar">');
  for (var i = 0, max = actions.length; i < max; i ++)
  {
    // todo hack attack
    if (actions[i] == 'insertImage')
      document.write('<input class="btninsertImage" type="button" title="'+actions[i]+'" value="" onclick="wsEditorCommand(\''+this.idIf+'\', \''+actions[i]+'\', \''+this.options[4]+'\');" id="'+this.idIf+'_'+actions[i]+'; return false;" value="'+actions[i]+'" /> ');
    else if (actions[i] == 'clean')
      document.write('<input class="btnclean" type="button" title="'+actions[i]+'" value="" onclick="wsEditorCommand(\''+this.idIf+'\', \''+actions[i]+'\');" id="'+this.idIf+'_'+actions[i]+'; return false;" value="'+actions[i]+'" /> ');
    else
      document.write('<input class="btn'+actions[i] +'" type="button" title="'+actions[i]+'" value="" onclick="wsEditorCommand(\''+this.idIf+'\', \''+actions[i]+'\');" id="'+this.idIf+'_'+actions[i]+'; return false;" value="'+actions[i]+'" /> ');
  }
  document.write('</div>');
}


wsEditor.prototype.generate_edit_box = function () 
{
  document.write('<input type="hidden" name="'+this.originalName+'" id="'+this.id+'" value="'+''+'" />');
  var editorHidden = document.getElementById(this.id);

  if ((is_ie || is_opera) || is_gecko)
  {
    var myfunci = wsEditorCreateLoader(this.id, this.idIf);
    var iframe = document.createElement("iframe");
    iframe.designMode = 'on';
    iframe.style.display = 'block';
    iframe.style.width   = this.options[1];
    iframe.style.height  = this.options[2];

    iframe.onload = myfunci(this.id, this.idIf);
    editorHidden.parentNode.appendChild(iframe);
    iframe.id   = this.idIf;
    iframe.name = this.idIf;

    // get the real field's data
    elements = document.getElementsByTagName('textarea');
    for (var i = 0; i < elements.length; i ++)
    {
        element = elements[i];

        if (element.name == this.options[0])
        {
            initial_value = element.value;
            break;
        }
    }

    iframe.contentWindow.document.open();
    iframe.contentWindow.document.write('<html><body style="background: #fff; margin: 3px; font-family: \'Arial\'; font-size: 12px;">'+initial_value+'</body></html>');
    iframe.contentWindow.document.close();
  }

  // textarea
  document.write('<textarea onpaste="wsEditorUpdateContent(\''+this.id+'\', this.value);" onkeyup="wsEditorUpdateContent(\''+this.id+'\', this.value);" style="display: none; width: '+this.options[1]+'; height: '+this.options[2]+'; visibility: hidden;" id="'+this.idTa+'">'+initial_value+'</textarea>');
}


wsEditor.prototype.generate_mode_switcher = function ()
{
  document.write('<div class="modeswitcher"><div style="float: right; padding-right: 10px;" id="'+this.id+'_switcher_indicator"></div><span id="'+this.id+'_switcher_html" title="Cambiar a modo HTML" class="button" onclick="wsEditorSwitchMode(\''+this.id+'\', \'code\');">Modo HTML</span> <span id="'+this.id+'_switcher_wysiwyg" title="Cambiar a modo visual" class="button" onclick="wsEditorSwitchMode(\''+this.id+'\', \'wysiwyg\');">Modo Visual</span></div>');
}


wsEditor.prototype.init = function () 
{
  if ((is_ie || is_opera) || is_gecko)
  {
    // activate edition mode
    var eIframe = document.getElementById(this.idIf);
    eIframe.onkeypress = function () { wsEditorEvent(); }
    eIframe.onkeydown = function () { wsEditorEvent(); }
    eIframe.onpaste = function () { wsEditorEventPaste(); }
    eIframe.contentWindow.document.onkeydown = function () { wsEditorEvent(); }

    var e = eIframe.contentWindow.document;

    elements = document.getElementsByTagName('textarea');
    for (var i = 0; i < elements.length; i ++)
    {
        element = elements[i];

        if (element.name == this.options[0])
            break;
    }

    element.parentNode.removeChild(element);

    wsEditorSwitchMode(this.id, 'code');
    wsEditorSwitchMode(this.id, 'wysiwyg');

  }
}


function wsEditorCreateLoader(id, iframe_id)
{
  return function(id, iframe_id) { wsEditorLoaded(id, iframe_id); }
}


function wsEditorPastedContent(sEditorIdIframe)
{
  var e = document.getElementById(sEditorIdIframe).contentWindow.document;
  var eIframeBody = e.body;
  var aTags2Replace = new Array('font', 'span', 'tr', 'td', 'table', 'tbody');

  for (var i = 0, max = aTags2Replace.length; i < max; i ++)
  {
    while(eIframeBody.getElementsByTagName(aTags2Replace[i]).length > 0)
    {
      fonttags = eIframeBody.getElementsByTagName(aTags2Replace[i])
      fonttags[0].removeNode(false)
    }
  }

  wsEditorUpdateContent(e.body.myWsEditorId, e.body.innerHTML);
}

function wsEditorEventUpdateContent(wsEditorId, obj)
{
  parent.wsEditorUpdateContent(wsEditorId, obj.body.innerHTML);
}


function wsEditorLoaded(sEditorId, sEditorIdIframe)
{
  if (!document.getElementById(sEditorIdIframe))
  {
    setTimeout('wsEditorLoaded(\''+sEditorId+'\', \''+sEditorIdIframe+'\')', 10);
    return false;
  }
  
  var doc = document.getElementById(sEditorIdIframe).contentWindow.document;
  doc.body.myWsEditorId = sEditorId;

  if ((is_ie || is_opera))
  {
    doc.body.onpaste = function () 
    {
      var sNewVal = window.clipboardData.getData('Text', sNewVal);
      this.pastedText = sNewVal;

      setTimeout('wsEditorPastedContent(\''+sEditorIdIframe+'\')', 25);
    }

    doc.body.onkeyup   = function () { parent.wsEditorUpdateContent(this.myWsEditorId, this.innerHTML) } ;
    doc.body.onchange  = function () { parent.wsEditorUpdateContent(this.myWsEditorId, this.innerHTML) } ;
    doc.body.ondragend = function () { parent.wsEditorUpdateContent(this.myWsEditorId, this.innerHTML) } ;
    doc.body.onresizeend = function () { parent.wsEditorUpdateContent(this.myWsEditorId, this.innerHTML) } ;
    doc.body.onchange  = function () { parent.wsEditorUpdateContent(this.myWsEditorId, this.innerHTML) } ;
    doc.body.onkeyup();
  }
  else if (is_gecko)
  {
    doc.wsEditorId = sEditorId;
    doc.addEventListener('paste', function () 
    {
      var sNewVal = window.clipboardData.getData('Text', sNewVal);
      this.pastedText = sNewVal;

      setTimeout('wsEditorPastedContent(\''+sEditorIdIframe+'\')', 25);
    }, true);

      var mufunc = wsEditorEventUpdateContent(sEditorId, doc);
		  doc.addEventListener('keyup', function() { wsEditorEventUpdateContent(sEditorId, doc)}, true);
		  doc.addEventListener('dragexit', function() { wsEditorEventUpdateContent(sEditorId, doc)}, true);
		  doc.addEventListener('mouseup', function() { wsEditorEventUpdateContent(sEditorId, doc)}, true);
		  doc.addEventListener('command', function() { wsEditorEventUpdateContent(sEditorId, doc)}, true);
  }


  if ((is_ie || is_opera) || is_gecko)
    wsEditorSwitchMode(sEditorId, 'wysiwyg');
  else
    wsEditorSwitchMode(sEditorId, 'code');
}


function wsEditorInsertImage(sEditorId, img_src)
{
  var win = document.getElementById(sEditorId).contentWindow;
  var e = win.document;

  // creamos el nodo
  var im = e.createElement('img');
  im.src = img_src;
  
  if ((is_ie || is_opera))
  {
    e.execCommand('insertImage', '', img_src);
    // e.body.appendChild(im);
    // var oControlRange = e.body.createControlRange();
    // oControlRange.add(im);
    // oControlRange.select();
  }
  else //mozilla
  {
    insertNodeAtSelection(win, im);
  }

  wsEditorUpdateContent(e.body.myWsEditorId, e.body.innerHTML);
}

// external functions (not to be called from within the editor object
function wsEditorCommand(sEditorId, sCommand)
{
  if (sCommand == 'createLink')
    return wsEditorLink(sEditorId);

  var e = document.getElementById(sEditorId).contentWindow.document;

  if (sCommand == 'insertImage')
  {
    window.open('/cuenta/imagenes/?sEditorId='+sEditorId, '_blank', 'width=520,height=500,status=yes,resizable=yes,scrollbars=1');
    return;
  }

  if (sCommand == 'clean')
  {
    // todo hack, esto petará en cuanto se desincronicen
    // loadXMLDoc('http://'+document.location.hostname+':'+document.location.port+'/site/clean_html', 'editorId='+sEditorId+'&content='+escape(e.body.innerHTML));
    return;
  }

  if (arguments[2])
    e.execCommand(sCommand, arguments[2], null);
  else
    e.execCommand(sCommand, false, null);

  // we are pretty sure the iframe is active
  // todo we should use the iframe id
  wsEditorUpdateContent(e.body.myWsEditorId, e.body.innerHTML);
}

function wsEditorSwitchMode(sEditorId, sNewMode)
{
  var buttonHtml    = document.getElementById(sEditorId+'_switcher_html');
  var buttonWysiwyg = document.getElementById(sEditorId+'_switcher_wysiwyg');
  var eIframe   = document.getElementById(sEditorId+'If');
  var eTextarea = document.getElementById(sEditorId+'Ta');
  var content   = '';
  var toolbar   = document.getElementById(sEditorId+'Toolbar');
  var indicator = document.getElementById(sEditorId+'_switcher_indicator');

  if ((sNewMode == 'code' && eTextarea.style.display == 'block') ||
      (sNewMode == 'wysiwyg' && eIframe.style.display == 'block'))
    return;


  switch (sNewMode)
  {
    case 'code':
      if ((is_ie || is_opera) || is_gecko)
      {
        eIframe.style.display      = 'none';
        eIframe.style.visibility   = 'hidden';

        // retrieve content

        // TODO hack to prevent IE error
        if (eIframe.contentWindow.document.body)
            content = eIframe.contentWindow.document.body.innerHTML;
      }
      else
        content = document.getElementById(sEditorId).value;

      eTextarea.style.display    = 'block';
      eTextarea.style.visibility = 'visible';

      eTextarea.value = content;

      buttonHtml.className = 'button unselectable';
      buttonHtml.disabled = 'disabled';
      buttonWysiwyg.className = 'button selectable';
      buttonWysiwyg.disabled = '';
      toolbar.disabled = 'disabled';
      indicator.innerHTML = 'Modo <strong>HTML</strong>';

      break;

    case 'wysiwyg':
      eTextarea.style.display    = 'none';
      eTextarea.style.visibility = 'hidden';

      // retrieve content
      content = eTextarea.value;
      var e = eIframe.contentWindow.document;

      eIframe.style.display      = 'block';
      eIframe.style.visibility   = 'visible';

      e.body.innerHTML = content;

      e.designMode = 'on';

      buttonWysiwyg.className = 'button unselectable';
      buttonWysiwyg.disabled = 'disabled';
      buttonHtml.className = 'button selectable';
      buttonHtml.disabled = '';
      toolbar.disabled = '';
      indicator.innerHTML = 'Modo <strong>Visual</strong>';
      break;
  }
}


function wsEditorLink(sEditorId)
{
  var e     = document.getElementById(sEditorId).contentWindow.document;
  
  if ((is_ie || is_opera))
  {
    var range = e.selection.createRange();
    var str   = range.text;
  }
  else
    var range = document.getElementById(sEditorId).contentWindow.getSelection();

  var oRef  = document.createElement('a');

  var link = window.prompt("URL:","http://");

  if (link == 'http://' || link == 'ftp://' || link == 'irc://' || !link)
    return;

  oRef.href = link;

  if ((is_ie || is_opera)) {
    oRef.innerText = str;
    range.pasteHTML(oRef.outerHTML);
  }
  else {
    var str2 = oRef.innerHTML;
    oRef.appendChild(e.createTextNode(''+range));
    insertNodeAtSelection(document.getElementById(sEditorId).contentWindow, oRef);
  }

    wsEditorUpdateContent(e.body.myWsEditorId, e.body.innerHTML);
}


function wsEditorUpdateContent(sEditorId, content)
{
  document.getElementById(sEditorId).value = content;
}

function wsEditorUpdateContentRemote(str)
{
  eval(str);
  var eIframe   = document.getElementById(res.editorId);
  eIframe.contentWindow.document.body.innerHTML = res.content;
}



function insertNodeAtSelection(win, insertNode)
{
    // get current selection
    var sel = win.getSelection();

    // get the first range of the selection
    // (there's almost always only one range)
    var range = sel.getRangeAt(0);

    // deselect everything
    sel.removeAllRanges();

    // remove content of current selection from document
    range.deleteContents();

    // get location of current selection
    var container = range.startContainer;
    var pos = range.startOffset;

    // make a new range for the new selection
    range=document.createRange();

    if (container.nodeType==3 && insertNode.nodeType==3) {

      // if we insert text in a textnode, do optimized insertion
      container.insertData(pos, insertNode.nodeValue);

      // put cursor after inserted text
      range.setEnd(container, pos+insertNode.length);
      range.setStart(container, pos+insertNode.length);

    } else {


      var afterNode;
      if (container.nodeType==3) {

        // when inserting into a textnode
        // we create 2 new textnodes
        // and put the insertNode in between

        var textNode = container;
        container = textNode.parentNode;
        var text = textNode.nodeValue;

        // text before the split
        var textBefore = text.substr(0,pos);
        // text after the split
        var textAfter = text.substr(pos);

        var beforeNode = document.createTextNode(textBefore);
        var afterNode = document.createTextNode(textAfter);

        // insert the 3 new nodes before the old one
        container.insertBefore(afterNode, textNode);
        container.insertBefore(insertNode, afterNode);
        container.insertBefore(beforeNode, insertNode);

        // remove the old node
        container.removeChild(textNode);

      } else {

        // else simply insert the node
        afterNode = container.childNodes[pos];
        container.insertBefore(insertNode, afterNode);
      }

      range.setEnd(afterNode, 0);
      range.setStart(afterNode, 0);
    }

    sel.addRange(range);
}

var regExp = /<\/?[^>]+>/gi;

function ReplaceTags(xStr){
  xStr = xStr.replace(regExp,"");
  return xStr;
}
