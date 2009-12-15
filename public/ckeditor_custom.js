CKEDITOR.config.customConfig = '';
CKEDITOR.config.toolbar = 'Full';
CKEDITOR.config.toolbar_Full =
[
    ['Source','-','Preview','Maximize'],
    ['Cut','Copy','Paste','PasteText','PasteFromWord'],
    ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
    '/',
    ['Bold','Italic','Strike'],
    ['NumberedList','BulletedList','-','Blockquote'],
    ['JustifyLeft','JustifyCenter','JustifyRight'],
    ['Link','Unlink','Anchor'],
    ['Image','Table','HorizontalRule','SpecialChar'],
    ['Styles','Format'],
];

CKEDITOR.config.filebrowserImageBrowseUrl = '/cuenta/imagenes';
CKEDITOR.config.filebrowserImageUploadUrl = '/cuenta/imagenes';
CKEDITOR.config.filebrowserWindowWidth = '640';
CKEDITOR.config.filebrowserWindowHeight = '480';
CKEDITOR.config.resize_enabled = false;
CKEDITOR.config.language = 'es';

CKEDITOR.addStylesSet('gm',[{name:'Marker: Yellow',element:'span',styles:{'background-color':'Yellow'}},{name:'Big',element:'big'},{name:'Small',element:'small'},{name:'Typewriter',element:'tt'},{name:'Código fuente',element:'code'},{name:'Texto borrado',element:'del'},{name:'Cita',element:'cite'},{name:'Imagen a la izquierda',element:'img',attributes:{style:'padding: 5px; margin-right: 5px',border:'2',align:'left'}},{name:'Imagen a la derecha',element:'img',attributes:{style:'padding: 5px; margin-left: 5px',border:'2',align:'right'}}]);

CKEDITOR.config.stylesCombo_stylesSet = 'gm';
CKEDITOR.config.skin = 'v2';
