var dparts = document.domain.split('.');
dparts = dparts.reverse();
var ADOMAIN = '.' + dparts[1] + '.' + dparts[0];
			
function wysiwyg_mode(mode){
    if (confirm('¿Estás seguro?')) {
        slnc.setPref('wysiwyg', mode);
        document.location = document.location;
    }
}

/**
 * Realiza diversas tareas de configuración de la página.
 * @param {Object} user_is_authed
 * @param {Object} contents
 */
function cfgPage(user_is_authed, contents, controller, action, model_id, newsessid, abtest, ads_shown){
	
    slnc.setupAdClicks();
	
    pageTracker = st.getTracker();
    if (newsessid) 
        pageTracker.setVar('_xnvi', newsessid);
    pageTracker.initData();
    pageTracker.setVar('_xc', controller);
    pageTracker.setVar('_xa', action);
    pageTracker.setVar('_xmi', model_id);
	
	
	if (ads_shown)
		pageTracker.setVar('_xad', ads_shown);
    
    if (abtest) 
        pageTracker.setVar('_xab', abtest);
    
    pageTracker.trackPageview(user_is_authed, contents);
	
	SyntaxHighlighter.all()
}

function form_sym_action(form_id, initial_str, new_str){
	var f = document.getElementById(form_id);
    if (!f) {
        alert(form_id + ' not found');
        return;
    }
    
    f.action = f.action.replace(initial_str, new_str);
    f.submit();
}

function showblock(id){
	$j('#'+id).css('display', 'block').css('visibility', 'visible');
}

function hideblock(id){
	$j('#'+id).css('display', 'none').css('visibility', 'hidden');
}

function showinline(id){
	$j('#'+id).css('display', 'inline').css('visibility', 'visible');
}

function hideinline(id){
	hideblock(id);
}

function create_new_option(name){
    var n = $j('<input type="text" />');
	n.attr('name', name);
	n.addClass('text');
	$j('#newoptions').append(n).append($j('<br />'));
}

function setpref(prefname, prefval){
    document.cookie = prefname + 'pref=' + prefval + '; expires=Thu, 2 Aug 2010 20:47:11 UTC; domain='+ADOMAIN+'; path=/';
    document.location = '/';
}

function rate_comment(comment_id, cvt_name, cvt_id) {
	$j.get('/comments/rate?comment_id=' + comment_id + '&rate_id=' + cvt_id + '&redirto=' + document.location, function(data) {
		$j('#moderate-comments-opener-rating' + comment_id).html(data);
	})
    hideinline('moderate-comments' + comment_id);
    return false;
}

function report_comment(comment_id){
	jQuery.facebox({ ajax: '/site/report_comment_form/'+comment_id });
    return false;
}

function new_message(user_id){
	jQuery.facebox({ ajax: '/cuenta/mensajes/new?id='+user_id });
    return false;
}

function report_user(user_id){
	jQuery.facebox({ ajax: '/site/report_user_form/'+user_id });
    return false;
}

function report_content(content_id){
	jQuery.facebox({ ajax: '/site/report_content_form/'+content_id });
    return false;
}

function close_content(content_id){
	jQuery.facebox({ ajax: '/site/close_content_form/'+content_id });
    return false;
}


function recommend_to_friend(content_id){
	jQuery.facebox({ ajax: '/site/recommend_to_friend?content_id='+content_id});
    return false;
}

function disable_rating_controls() {
    for (key in comments) {
        var dEl = $j('#moderate-comments-opener-rating' + key);
        if (dEl && dEl.html() == 'Ninguna') 
            hideinline('moderate-comments-opener' + key);
    }
}

function check_comments_controls(user_is_mod, user_id, user_last_visited_on, unix_now, comments_ratings, remaining_slots, old_enough, user_is_hq, first_time_content, do_autoscroll){
    // NO calcular tiempo unix_now por el cliente, es una caja de pandora
	var scroll_to_comment; // contiene el elemento al que hacer scroll
	
    for (key in comments) {		
        if (comments[key][1] != user_id && old_enough) // Puede valorarlo
        {
            if (comments_ratings[key] != undefined) 
                $j('#moderate-comments-opener-rating' + key).html(comments_ratings[key]);
            
            if ($j('#moderate-comments-opener' + key) != undefined && (comments_ratings[key] != undefined || remaining_slots > 0)) // necesario por un error js raro
                showinline('moderate-comments-opener' + key);
        }
        
        if (comments[key][0] > user_last_visited_on && comments[key][1] != user_id) {
			$j('#comment' + key).addClass('new');
			// hacemos scroll excepto que sea primera pag y primer comment
			if ((!first_time_content) && !scroll_to_comment) {
				scroll_to_comment = $j('#comment' + key);
			}
		}
		cur_is_first = false;
		
        
        if (((user_is_mod && comments[key][0] > unix_now - 86400 * 365) || (comments[key][1] == user_id && comments[key][0] > unix_now - 60 * 15))) {
            $j('#comment' + key + 'editlink').removeClass('hidden');
            if (user_is_mod) 
              $j('#comment' + key + 'dellink').removeClass('hidden');
        }
        var rpc = $j('#report-comments'+key); 
        if (user_is_hq && !user_is_mod && rpc) {
			rpc.removeClass('hidden');
        }
    }
	
	if (do_autoscroll == '1' && scroll_to_comment && !first_time_content) {
		$j(document).ready(function() {
			$j(window).scrollTo(scroll_to_comment, 750, { easing:'swing', queue:true, axis:'y', offset:-60 });
		});
	}
}

function open_new_content_selector(){
	$j('#new-content-selector').removeClass('hidden');
	return false;
}

function close_new_content_selector(){
	$j('#new-content-selector').addClass('hidden');
	return false;
}

function mark_new(item_id, base){
    var d = $j("#"+ base + item_id);
    if (d) 
		d.addClass('updated');
}

function mark_visited(item_id){
    $j('.content' + item_id).removeClass('new');
}

function mailto(p1){
    var p2 = 'gamersmafia';
    document.location = 'mailto:' + p1 + '@' + p2 + '.com?Subject=Email sobre Gamersmafia';
}

var agt = navigator.userAgent.toLowerCase();
var appVer = navigator.appVersion.toLowerCase();

var is_minor = parseFloat(appVer);
var is_major = parseInt(is_minor);
var is_opera = (agt.indexOf("opera") != -1);

var is_mac = (agt.indexOf("mac") != -1);
var iePos = appVer.indexOf('msie');
if (iePos != -1) {
    if (is_mac) {
        var iePos = agt.indexOf('msie');
        is_minor = parseFloat(agt.substring(iePos + 5, agt.indexOf(';', iePos)));
    }
    else 
        is_minor = parseFloat(appVer.substring(iePos + 5, appVer.indexOf(';', iePos)));
    is_major = parseInt(is_minor);
}

var is_konq = false;
var kqPos = agt.indexOf('konqueror');
if (kqPos != -1) {
    is_konq = true;
    is_minor = parseFloat(agt.substring(kqPos + 10, agt.indexOf(';', kqPos)));
    is_major = parseInt(is_minor);
}

var is_safari = ((agt.indexOf('safari') != -1) && (agt.indexOf('mac') != -1)) ? true : false;
var is_khtml = (is_safari || is_konq);

var is_gecko = ((!is_khtml) && (navigator.product) && (navigator.product.toLowerCase() == "gecko")) ? true : false;
var is_gver = 0;
if (is_gecko) 
    is_gver = navigator.productSub;


var is_ie = ((iePos != -1) && (!is_opera) && (!is_khtml));

var req;

function skinselector(val){
    if (val == 'mis-skins') 
        document.location = '/cuenta/skins';
    else {
        /* TODO hacerlo mejor */
        document.cookie = 'skin=' + val + '; expires=Thu, 2 Aug 2100 20:47:11 UTC; domain='+ADOMAIN+'; path=/';
        document.location = '/';
    }
}

/**
 * Used to call function f with given arguments
 * BindArguments(setactivewmsecondary, masterSections[i]);
 * @param {Object} fn
 */
function BindArguments(fn){
    var args = [];
    for (var n = 1; n < arguments.length; n++) 
        args.push(arguments[n]);
    return function(){
        return fn.apply(this, args);
    };
}

function switch_block_visi(block_base) {
	var max = block_base + 'max';
	var min = block_base + 'min';
		
	if ($j('#'+min).css('display') != 'none') {
		hideblock(min);
		showblock(max);
	}
	else {
    	hideblock(max);
		showblock(min);
	}
	return false;
}

function setratebar(v)
{
  $j('#ratebar').css('background-position', "0px -" + (287 + (v-1) * 13) + "px");
}

function rate(content_id, v)
{
	$j.get('/site/rate_content?content_rating[rating]=' + v + '&content_rating[content_id]='+content_id, function(data) {
		$j('#ratebar-container').html(data);
	})
  return false;
}


var GM = GM || {};
GM = {};
GM.menu = function(){
	var sawbottom_mode = 'comunidad';
	var sawbottom_cur = '';
	var sawbottom_cur_int = '';
	
	// add event handlers to arrows
	var fn = function() { GM.menu.sawbottom_cancel(); }
	$j('.sawtop-arrow').mouseout(fn);
	
	return {
		sawbottom: function(mode) {
			this.sawbottom_cancel();
			sawbottom_cur = mode;
			if (sawbottom_cur_int) {
				window.status = 'int found, deleting';
				clearTimeout(sawbottom_cur_int);
			}
			
			sawbottom_cur_int = setTimeout("GM.menu.sawbottom_real('"+mode+"')", 200);
		},
	
		sawbottom_real: function(mode) {
			if (mode == sawbottom_cur || arguments.length == 2) {
				  
				$j('#sawli-' + sawbottom_mode).removeClass('alter');
				$j('#sawbody-' + sawbottom_mode).addClass('hidden');
				
				var d = $j('#sawli-' + mode);
				if (d) {
					d.addClass('alter');
					$j('#sawbody-' + mode).removeClass('hidden');
					sawbottom_mode = mode;
				}
			}
		},
	
		sawbottom_cancel: function() {
			if (sawbottom_cur_int)
				clearTimeout(sawbottom_cur_int);
			sawbottom_cur = '';
		},
		
		sawdropdown_hide: function(id) {
			var the_dropdown =  $j('#'+id);
			the_dropdown.addClass('hidden');
		},
		
		sawdropdown_cancel_hiding: function(id) {
			var the_dropdown =  $j('#'+id);
			var theint = the_dropdown.data('outint');
			if (theint) {
				clearInterval(theint);
				the_dropdown.data('outint', undefined);
			}
		},
		
		showSawDropDown: function(id) {
			var the_dropdown =  $j('#'+id);

			$j('body').bind('mouseover', function(event) {
				// Creo y lanzo un timeout para cerrar el menú si dentro de 1000ms no se ha eliminado el timeout 
				var newint = the_dropdown.data('outint');
				if (newint)
					clearInterval(newint);
				the_dropdown.data('outint', setTimeout("GM.menu.sawdropdown_hide('"+id+"')", 750));
			});
			
			the_dropdown.bind('mouseover', function(e){ 
				e.stopPropagation(); 
				GM.menu.sawdropdown_cancel_hiding(id);} 
			);
			the_dropdown.children('.saw-dropdownlist').bind('mouseover', function(e){ e.stopPropagation(); GM.menu.sawdropdown_cancel_hiding(id); } );
			// TODO no estamos haciendo unbind
			
				the_dropdown.removeClass('hidden');
				return false;
			}
		}
}();

GM.utils = function() {
	return {
		gototop: function() {
			if ($j.browser.msie && jQuery.browser.version == '6.0')
				document.location = '#';
			else
				$j(window).scrollTo(0, 750, { easing:'swing', queue:true, axis:'y', offset:-60 });
			return false;
		}
	}
}();

GM.personalization = function(){
	return {
		set_default_portal: function (user_is_authed, new_portal) {
			if (user_is_authed)
				$j.get('/cuenta/cuenta/set_default_portal?new_portal=' + new_portal);
			else
				slnc.setPref('defportal', new_portal);
			return false;
		},
		add_quicklink: function (code, url) {
			$j.get('/cuenta/cuenta/add_quicklink?code=' + code + '&url='+url);
			//$j('#add-to-quicklinks').remove();
			// TODO habría que actualizar la caja de quicklinks para hacer return false;
		},
		del_quicklink: function (code) {
			$j.get('/cuenta/cuenta/del_quicklink?code=' + code);
			// TODO habría que actualizar la caja de quicklinks para hacer return false;
		},
		add_user_forum: function (id, url) {
			$j.get('/cuenta/cuenta/add_user_forum?id=' + id + '&url='+url);
			$j('#add-to-user-forums').addClass('hidden');
			$j('#del-from-user-forums').removeClass('hidden');
			return false;
		},
		del_user_forum: function (id) {
			$j.get('/cuenta/cuenta/del_user_forum?id=' + id);
			$j('#del-from-user-forums').addClass('hidden');
			$j('#add-to-user-forums').removeClass('hidden');
			return false;
		},
		update_user_forums_order: function(user_id, buckets1, buckets2, buckets3) {
			$j.get('/cuenta/cuenta/update_user_forums_order?user_id=' + user_id + '&' + buckets1 + '&'+ buckets2 + '&'+ buckets3);
		}
	}
}();

function closeFacebox() {
	$j(document).trigger('close.facebox');

	return false;
}


$j.fn.insertAtCaret = function (myValue) {
	return this.each(function(){
			//IE support
			if (document.selection) {
					this.focus();
					sel = document.selection.createRange();
					sel.text = myValue;
					this.focus();
			}
			//MOZILLA / NETSCAPE support
			else if (this.selectionStart || this.selectionStart == '0') {
					var startPos = this.selectionStart;
					var endPos = this.selectionEnd;
					var scrollTop = this.scrollTop;
					this.value = this.value.substring(0, startPos)+ myValue+ this.value.substring(endPos,this.value.length);
					this.focus();
					this.selectionStart = startPos + myValue.length;
					this.selectionEnd = startPos + myValue.length;
					this.scrollTop = scrollTop;
			} else {
					this.value += myValue;
					this.focus();
			}
	});
};
