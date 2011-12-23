var $j = jQuery;
$j.noConflict();

var slnc = slnc || {};

slnc = {
    /**
     * Añade una string arbitraria a todos los enlaces contenidos en un tag.
     *
     * @param {Object} container_div el elemento dentro del que se buscarán los enlaces
     * @param {Object} link_tag lo que se añade
     */
    marklinks: function(container_div, link_tag){
        var el = document.getElementById(container_div);
        if (el == undefined) 
            return;
        var oItems = el.getElementsByTagName('a');
        var sep;
        
        for (var i = 0; i < oItems.length; i++) {
            sep = (oItems[i].href.indexOf('?') != -1) ? '&' : '?';
            oItems[i].href = oItems[i].href + sep + link_tag;
        }
    },
    
    /**
     * Añade onclick handlers a todos los enlaces que tengan la clase slncadt.
     */
    setupAdClicks: function(){
        $j('a.slncadt').click(function(){
            slnc.adClick(this)
        });
    },
    
    /**
     * Registra un click externo.
     */
    adClick: function(a_tag){
        var url = '/site/cnta?url=' + encodeURIComponent(a_tag.href);
        if (a_tag.id == undefined) 
            return;
        
        url = url + '&element_id=' + a_tag.id;
        $j.ajax({
            url: url,
            async: false
        });
    },
    
    /**
     * Guarda una preferencia en cookie.
     */
    setPref: function(name, val){
        if (ADOMAIN == undefined) {
            alert("Undefined ADOMAIN");
        }
        document.cookie = name + 'pref=' + val + '; expires=Thu, 2 Aug 2010 20:47:11 UTC; path=/; domain=' + ADOMAIN;
        document.location = '/';
    },
    
    /**
     * Devuelve el dominio de segundo nivel actual. Eg: "gamersmafia.com"
     */
    sld_domain: function(){
        dparts = document.domain.split('.').reverse();
        return '.' + dparts[1] + '.' + dparts[0];
    },
    
    /**
     * Oculta el elemento con id tal.
     */
    hide: function(id){
        $j('#' + id).css('visibility', 'hidden').css('display', 'none');
    },
    
    /**
     * Selecciona todos los checkboxes que haya en la misma tabla. Los checkboxes
     * tienen que estar en la primera columna.
     *
     * @param {Object} sourceEl
     */
    checkboxSwitchGroup: function(sourceEl){
        var el = sourceEl;
        var par = sourceEl.parentNode;
        
        if (typeof(par) != 'object' ||
        typeof(par.parentNode) != 'object' ||
        typeof(par.parentNode.parentNode) != 'object') 
            return;
        
        var table = par.parentNode.parentNode;
        var new_state = (sourceEl.checked == true) ? true : false;
        
        for (var i = 1, max = table.childNodes.length; i < max; i++) {
            var tr = table.childNodes[i];
            
            if (tr.nodeName.toLowerCase() != 'tr') 
                continue;
            
            var index = (tr.childNodes[0].nodeName.toLowerCase() == 'td') ? 0 : 1;
            
            if (tr.childNodes[index].nodeName.toLowerCase() != 'td') 
                continue;
            
            if (tr.childNodes[index].childNodes[0].nodeName.toLowerCase() == 'input' &&
            tr.childNodes[index].childNodes[0].type.toLowerCase() == 'checkbox') {
                if (tr.childNodes[index].childNodes[0].disabled) 
                    continue;
                
                if (tr.childNodes[index].childNodes[0].checked == new_state) 
                    continue;
                
                tr.childNodes[index].childNodes[0].click();
            }
        }
    },
    
    hilit_row: function(node, className){
        // check status
        var checked = node.checked;
        var parent = node.parentNode;
        
        while (!(parent.nodeType == 1 && parent.nodeName == 'TR')) {
            parent = parent.parentNode;
        }
        
        var re = new RegExp(' ' + className);
        
        if (checked) // must select
        {
            if (!re.test(parent.className)) 
                parent.className = parent.className + ' ' + className;
        }
        else // must deselect
        {
            while (re.test(parent.className)) 
                parent.className = parent.className.replace(re, '');
        }
    },
    
    hilit_row_by_radio: function(node, className){
        /* cuando seleccionamos un radio siempre se queda seleccionado, as� que hay
         * que quitar el estilo a todas las filas y luego pon�rselo a la fila actual */
        // check status
        var checked = node.checked;
        
        var parent = node.parentNode;
        var greatparent = parent.parentNode;
        
        // cogemos la fila actual
        while (!(parent.nodeType == 1 && parent.nodeName == 'TR')) 
            parent = parent.parentNode;
        
        var re = new RegExp(' ' + className);
        var re2 = new RegExp('^' + className);
        
        // quitamos clase a todas las filas
        var ar_group_nodes = document.getElementsByName(node.name);
        
        for (var i = 0, max = ar_group_nodes.length; i < max; i++) {
            var node2 = ar_group_nodes[i];
            var parent2 = node2.parentNode;
            
            while (!(parent2.nodeType == 1 && parent2.nodeName == 'TR')) 
                parent2 = parent2.parentNode;
            
            while (re.test(parent2.className)) 
                parent2.className = parent2.className.replace(re, '');
            
            while (re2.test(parent2.className)) 
                parent2.className = parent2.className.replace(re2, '');
        }
        
        parent.className = parent.className + ' ' + className;
    },
    
    /**
     * Muestra el elemento con id tal. Por defecto display se pone en block
     * pero se puede pasar otro valor como segundo argumento.
     *
     * @param {Object} id
     */
    show: function(id){
        var s = $j('#' + id);
        s.css('visibility', 'visible');
        if (arguments[1]) 
            s.css('display', arguments[1]);
        else 
            s.css('display', 'block');
    }
};


$j(document).ready(function(){
    $j('textarea[maxlength]').keyup(function(){
        var jt = $j(this);
        var max = parseInt(jt.attr('maxlength'));
        if (jt.val().length > max) {
            jt.val(jt.val().substr(0, jt.attr('maxlength')));
        }
        // $j(this).parent().find('.charsRemaining').html('You have ' + (max - $j(this).val().length) + ' characters remaining'); 
    });
});
