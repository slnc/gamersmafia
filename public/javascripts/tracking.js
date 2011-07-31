/** TODO LIMPIAR ESTO
 *
 */
//-- Urchin On Demand Settings ONLY
var _uacct = ""; // set up the Urchin Account
var _userv = 1; // service mode (0=local,1=remote,2=both)
//-- UTM User Settings
var _ufsc = 1; // set client info flag (1=on|0=off)
var _udn = slnc.sld_domain(); // (auto|none|domain) set the domain name for cookies
var _uhash = "off"; // (on|off) unique domain hash for cookies
var _utimeout = "1800"; // set the inactive session timeout in seconds
var _ugifpath = "/__utm.gif"; // set the web path to the __utm.gif file
var _utsp = "|"; // transaction field separator
var _utitle = 1; // set the document title detect option (1=on|0=off)
var _ulink = 0; // enable linker functionality (1=on|0=off)
var _uanchor = 0; // enable use of anchors for campaign (1=on|0=off)
var _utcp = "/"; // the cookie path for tracking
var _usample = 100; // The sampling % of visitors to track (1-100).
//-- UTM Campaign Tracking Settings
var _uctm = 1; // set campaign tracking module (1=on|0=off)
var _ucto = "15768000"; // set timeout in seconds (6 month default)
var _uccn = "utm_campaign"; // name
var _ucmd = "utm_medium"; // medium (cpc|cpm|link|email|organic)
var _ucsr = "utm_source"; // source
var _uctr = "utm_term"; // term/keyword
var _ucct = "utm_content"; // content
var _ucid = "utm_id"; // id number
var _ucno = "utm_nooverride"; // don't override
//-- Auto/Organic Sources and Keywords

//-- Auto/Organic Keywords to Ignore
var _uOno = new Array();
//_uOno[0]="urchin";
//_uOno[1]="urchin.com";
//_uOno[2]="www.urchin.com";

//-- Referral domains to Ignore
var _uRno = new Array();
//_uRno[0]=".urchin.com";

var _uff, _udh, _udt, _ubl = 0, _udo = "", _uu, _ufns = 0, _uns = 0, _ur = "-", _ufno = 0, _ust = 0, _ubd = document, _udl = _ubd.location, _udlh = "", _uwv = "1";
_udt = new Date();
var _uhash = "on";
var _utimeout = "1800"; // set the inactive session timeout in seconds
// NO TE COMAS LA CABEZA TRON"!
var st = new Object({}); // Our namespace
//var _udn = "auto";
st.getTracker = function(){
    return new stmodule();
}

var stmodule = function(){
    this.vars = {}
}

stmodule.prototype.encode = function(e, isURI){
    var c = encodeURIComponent;
    return c instanceof Function ? (isURI ? encodeURI(e) : c(e)) : escape(e)
}

stmodule.prototype.decode = function(e, isURI){
    var c = decodeURIComponent, h;
    if (c instanceof Function) {
        try {
            h = isURI ? decodeURI(e) : c(e)
        }
        catch (k) {
            h = unescape(e)
        }
    }
    else {
        h = unescape(e)
    }
    return h;
}


stmodule.prototype.getEncodedVars = function(){
    var out = '';
    for (b in this.vars) {
        out += '&' + b + '=' + this.vars[b];

    }
    return out;
}

stmodule.prototype.setVar = function(k, v){
    this.vars[k] = v;
}

stmodule.prototype._sIN = function(n){
    if (!n)
        return false;
    for (var i = 0; i < n.length; i++) {
        var c = n.charAt(i);
        if ((c < "0" || c > "9") && (c != "."))
            return false;
    }
    return true;
}

stmodule.prototype._uVG = function(){
    return true;
}

function _sIN(n){
    if (!n)
        return false;
    for (var i = 0; i < n.length; i++) {
        var c = n.charAt(i);
        if ((c < "0" || c > "9") && (c != "."))
            return false;
    }
    return true;
}

function _sDomain(){
    if (!_udn || _udn == "" || _udn == "none") {
        _udn = "";
        return 1;
    }
    if (_udn == "auto") {
        var d = _ubd.domain;
        if (d.substring(0, 4) == "www.") {
            d = d.substring(4, d.length);
        }
        _udn = d;
    }
    _udn = _udn.toLowerCase();
    if (_uhash == "off")
        return 1;
    return _uHash(_udn);
}

stmodule.prototype.setupCookies = function(){
    var _uff, _udt, _ubl = 0, _udo = "", _uu, _ufns = 0, _uns = 0, _ur = "-", _ufno = 0, _ust = 0, _ubd = document, _udl = _ubd.location, _udlh = "", _uwv = "1";

    if (_udl.protocol == "file:")
        return;
    if (_uff && (!page || page == ""))
        return;
    var a, b, c, xx, v, z, k, x = "", s = "", f = 0;
    var nx = " expires=" + _sNx() + ";";
    var dc = _ubd.cookie;

    _udh = _sDomain();

  if (this.vars['_xnvi']) {
    _uu = this.vars['_xnvi'];
  }
  else
    _uu = Math.round(Math.random() * 2147483647);
    _udt = new Date();
    _ust = Math.round(_udt.getTime() / 1000);
    a = dc.indexOf("__stma=" + _udh);
    b = dc.indexOf("__stmb=" + _udh);
    c = dc.indexOf("__stmc=" + _udh);
    if (_udn && _udn != "") {
        _udo = " domain="+ slnc.sld_domain() +";";
    }
    if (_utimeout && _utimeout != "") {
        x = new Date(_udt.getTime() + (_utimeout * 1000));
        x = " expires=" + x.toGMTString() + ";";
    }
    if (_ulink) {
        if (_uanchor && _udlh && _udlh != "")
            s = _udlh + "&";
        s += _udl.search;
        if (s && s != "" && s.indexOf("__stma=") >= 0) {
            if (!(_sIN(a = _sGC(s, "__stma=", "&"))))
                a = "-";
            if (!(_sIN(b = _sGC(s, "__stmb=", "&"))))
                b = "-";
            if (!(_sIN(c = _sGC(s, "__stmc=", "&"))))
                c = "-";
            v = _sGC(s, "__stmv=", "&");
            z = _sGC(s, "__stmz=", "&");
            k = _sGC(s, "__stmk=", "&");
            xx = _sGC(s, "__stmx=", "&");
            if ((k * 1) != ((_uHash(a + b + c + xx + z + v) * 1) + (_udh * 1))) {
                _ubl = 1;
                a = "-";
                b = "-";
                c = "-";
                xx = "-";
                z = "-";
                v = "-";
            }
            if (a != "-" && b != "-" && c != "-")
                f = 1;
            else
                if (a != "-")
                    f = 2;
        }
    }
    if (f == 1) {
        _ubd.cookie = "__stma=" + a + "; path=" + _utcp + ";" + nx + _udo;
        _ubd.cookie = "__stmb=" + b + "; path=" + _utcp + ";" + x + _udo;
        _ubd.cookie = "__stmc=" + c + "; path=" + _utcp + ";" + _udo;
    }
    else
        if (f == 2) {
            a = _sFixA(s, "&", _ust);
            _ubd.cookie = "__stma=" + a + "; path=" + _utcp + ";" + nx + _udo;
            _ubd.cookie = "__stmb=" + _udh + "; path=" + _utcp + ";" + x + _udo;
            _ubd.cookie = "__stmc=" + _udh + "; path=" + _utcp + ";" + _udo;
            _ufns = 1;
        }
        else
            if (a >= 0 && b >= 0 && c >= 0) {
                _ubd.cookie = "__stmb=" + _udh + "; path=" + _utcp + ";" + x + _udo;
            }
            else {
                if (a >= 0)
                    a = _sFixA(_ubd.cookie, ";", _ust);

                else
                    a = _udh + "." + _uu + "." + _ust + "." + _ust + "." + _ust + ".1";
                _ubd.cookie = "__stma=" + a + "; path=" + _utcp + ";" + nx + _udo;
                _ubd.cookie = "__stmb=" + _udh + "; path=" + _utcp + ";" + x + _udo;
                _ubd.cookie = "__stmc=" + _udh + "; path=" + _utcp + ";" + _udo;
                _ufns = 1;
            }
    if (_ulink && xx && xx != "" && xx != "-") {
        xx = _uUES(xx);
        if (xx.indexOf(";") == -1)
            _ubd.cookie = "__stmx=" + xx + "; path=" + _utcp + ";" + nx + _udo;
    }
    if (_ulink && v && v != "" && v != "-") {
        v = _uUES(v);
        if (v.indexOf(";") == -1)
            _ubd.cookie = "__stmv=" + v + "; path=" + _utcp + ";" + nx + _udo;
    }
    // quiero el visitor_id
    var tmpo, visid;

    tmpo = _sFixA(_ubd.cookie, ";", _ust);


    for (var i = 0; i < 1; i++) {
        tmpo = tmpo.substring(tmpo.indexOf('.') + 1);
    }

    this.setVar('_xvi', tmpo.substring(0, tmpo.indexOf('.')))
    var ii = 0;
    for (var i = 0; i < 2; i++) {
        tmpo = tmpo.substring(tmpo.indexOf('.') + 1);
    }

    this.setVar('_xsi', tmpo.substring(0, tmpo.indexOf('.')))
    _sInfo("blip");
    _ufns = 0;
    _ufno = 0;
}

function _sFixA(c, s, t){
    if (!c || c == "" || !s || s == "" || !t || t == "")
        return "-";

    var a = _sGC(c, "__stma=" + _udh, s);
    var lt = 0, i = 0;
    if ((i = a.lastIndexOf(".")) > 9) {
        _uns = a.substring(i + 1, a.length);
        _uns = (_uns * 1) + 1;
        a = a.substring(0, i);
        if ((i = a.lastIndexOf(".")) > 7) {
            lt = a.substring(i + 1, a.length);
            a = a.substring(0, i);
        }
        if ((i = a.lastIndexOf(".")) > 5) {
            a = a.substring(0, i);
        }
        a += "." + lt + "." + t + "." + _uns;
    }
    return a;
}

function _sInfo(page){
    var p, s = "", dm = "", pg = _udl.pathname + _udl.search;
    if (page && page != "")
        pg = _sES(page, 1);
    _ur = _ubd.referrer;
    if (!_ur || _ur == "") {
        _ur = "-";
    }
    else {
        dm = _ubd.domain;
        if (_utcp && _utcp != "/")
            dm += _utcp;
        p = _ur.indexOf(dm);
        if ((p >= 0) && (p <= 8)) {
            _ur = "0";
        }
        if (_ur.indexOf("[") == 0 && _ur.lastIndexOf("]") == (_ur.length - 1)) {
            _ur = "-";
        }
    }
    s += "&stmn=" + _uu;
    if (_ufsc)
        s += _sBInfo();
    if (_uctm)
        s += _uCInfo();
    if (_utitle && _ubd.title && _ubd.title != "")
        s += "&stmdt=" + _sES(_ubd.title);
    if (_udl.hostname && _udl.hostname != "")
        s += "&stmhn=" + _sES(_udl.hostname);
    s += "&stmr=" + _ur;
    s += "&stmp=" + pg;

    return;
}


function _sBInfo(){
    var sr = "-", sc = "-", ul = "-", fl = "-", cs = "-";
    var n = navigator;
    if (self.screen) {
        sr = screen.width + "x" + screen.height;
        sc = screen.colorDepth + "-bit";
    }
    else
        if (self.java) {
            var j = java.awt.Toolkit.getDefaultToolkit();
            var s = j.getScreenSize();
            sr = s.width + "x" + s.height;
        }
    if (n.language) {
        ul = n.language.toLowerCase();
    }
    else
        if (n.browserLanguage) {
            ul = n.browserLanguage.toLowerCase();
        }

    if (_ubd.characterSet)
        cs = _sES(_ubd.characterSet);
    else
        if (_ubd.charset)
            cs = _sES(_ubd.charset);
    return "&stmcs=" + cs + "&stmsr=" + sr + "&stmsc=" + sc + "&stmul=" + ul;
}

stmodule.prototype.trackPageview = function(user_is_authed, contents){
	url = "http://" + document.domain + "/site/x?a=1" + this.getEncodedVars();
	if (user_is_authed && contents.length > 0)
		url = url + "&cids=" + contents.join(',');
		$j.get(url, function(data) {
			eval(data);
		});
}

function _uVoid(){
    return;
}

function _sGCS(){
    var t, c = "", dc = _ubd.cookie;
    if ((t = _sGC(dc, "__stma=" + _udh, ";")) != "-")
        c += _sES("__stma=" + t + ";+");
    if ((t = _sGC(dc, "__stmb=" + _udh, ";")) != "-")
        c += _sES("__stmb=" + t + ";+");
    if ((t = _sGC(dc, "__stmc=" + _udh, ";")) != "-")
        c += _sES("__stmc=" + t + ";+");
    if ((t = _sGC(dc, "__stmx=" + _udh, ";")) != "-")
        c += _sES("__stmx=" + t + ";+");
    if ((t = _sGC(dc, "__stmz=" + _udh, ";")) != "-")
        c += _sES("__stmz=" + t + ";+");
    if ((t = _sGC(dc, "__stmv=" + _udh, ";")) != "-")
        c += _sES("__stmv=" + t + ";");
    if (c.charAt(c.length - 1) == "+")
        c = c.substring(0, c.length - 1);
    return c;
}

function _sES(s, u){
    if (typeof(encodeURIComponent) == 'function') {
        if (u)
            return encodeURI(s);
        else
            return encodeURIComponent(s);
    }
    else {
        return escape(s);
    }
}

function _sGC(l, n, s){
    if (!l || l == "" || !n || n == "" || !s || s == "")
        return "-";
    var i, i2, i3, c = "-";
    i = l.indexOf(n);
    i3 = n.indexOf("=") + 1;
    if (i > -1) {
        i2 = l.indexOf(s, i);
        if (i2 < 0) {
            i2 = l.length;
        }
        c = l.substring((i + i3), i2);
    }
    return c;
}

stmodule.prototype.initData = function(){
    this.setupCookies();

    // Las putas cookies
    this.vars['_xr'] = this.encode(document.referrer);
    this.vars['_xu'] = this.encode(document.location);
  var e = document.getElementById('error');
  if (e)
    this.vars['_xe'] = e.innerHTML;
    var s = "" + document.location;

    this.vars['_xm'] = _sGC(s, "_xm=", "&");
  	this.vars['_xs'] = _sGC(s, "_xs=", "&");
  	this.vars['_xca'] = _sGC(s, "_xca=", "&");

    // this.vars['referer'] = this.encode(document.referrer);
}

// Leemos la información de cookies o inicializamos
// Enviamos la información por ajax
// If linker functionalities are enabled, it attempts to extract cookie values from the URL.
// Otherwise, it tries to extract cookie values from document.cookie.
// It also updates or creates cookies as necessary,
// then writes them back to the document object.
// Gathers all the appropriate metrics to send to the UCFE (Urchin Collector Front-end).
// var pageTracker = st.getTracker();
// pageTracker.initData();
// pageTracker.trackPageview();

function _sNx(){
    return (new Date((new Date()).getTime() + 63072000000)).toGMTString();
}

function _uHash(d){
    if (!d || d == "")
        return 1;
    var h = 0, g = 0;
    for (var i = d.length - 1; i >= 0; i--) {
        var c = parseInt(d.charCodeAt(i));
        h = ((h << 6) & 0xfffffff) + c + (c << 14);
        if ((g = h & 0xfe00000) != 0)
            h = (h ^ (g >> 21));
    }
    return h;
}

function _uCInfo(){
    if (!_ucto || _ucto == "") {
        _ucto = "15768000";
    }

    var c = "", t = "-", t2 = "-", t3 = "-", o = 0, cs = 0, cn = 0, i = 0, z = "-", s = "";
    if (_uanchor && _udlh && _udlh != "")
        s = _udlh + "&";
    s += _udl.search;
    var x = new Date(_udt.getTime() + (_ucto * 1000));
    var dc = _ubd.cookie;
    x = " expires=" + x.toGMTString() + ";";
    if (_ulink && !_ubl) {
        z = _uUES(_sGC(s, "__utmz=", "&"));
        if (z != "-" && z.indexOf(";") == -1) {
            _ubd.cookie = "__utmz=" + z + "; path=" + _utcp + ";" + x + _udo;
            return "";
        }
    }
    z = dc.indexOf("__utmz=" + _udh);
    if (z > -1) {
        z = _sGC(dc, "__utmz=" + _udh, ";");
    }
    else {
        z = "-";
    }
    t = _sGC(s, _ucid + "=", "&");
    t2 = _sGC(s, _ucsr + "=", "&");
    t3 = _sGC(s, "gclid=", "&");
    if ((t != "-" && t != "") || (t2 != "-" && t2 != "") || (t3 != "-" && t3 != "")) {
        if (t != "-" && t != "")
            c += "utmcid=" + _uEC(t);
        if (t2 != "-" && t2 != "") {
            if (c != "")
                c += "|";
            c += "utmcsr=" + _uEC(t2);
        }
        if (t3 != "-" && t3 != "") {
            if (c != "")
                c += "|";
            c += "utmgclid=" + _uEC(t3);
        }
        t = _sGC(s, _uccn + "=", "&");
        if (t != "-" && t != "")
            c += "|utmccn=" + _uEC(t);
        else
            c += "|utmccn=(not+set)";
        t = _sGC(s, _ucmd + "=", "&");
        if (t != "-" && t != "")
            c += "|utmcmd=" + _uEC(t);
        else
            c += "|utmcmd=(not+set)";
        t = _sGC(s, _uctr + "=", "&");
        if (t != "-" && t != "")
            c += "|utmctr=" + _uEC(t);
        else {
            t = _uOrg(1);
            if (t != "-" && t != "")
                c += "|utmctr=" + _uEC(t);
        }
        t = _sGC(s, _ucct + "=", "&");
        if (t != "-" && t != "")
            c += "|utmcct=" + _uEC(t);
        t = _sGC(s, _ucno + "=", "&");
        if (t == "1")
            o = 1;
        if (z != "-" && o == 1)
            return "";
    }
    /* if (c == "-" || c == "") {
        c = _uOrg();
        if (z != "-" && _ufno == 1)
            return "";
    }*/
    if (c == "-" || c == "") {
        if (_ufns == 1)
            c = _uRef();
        if (z != "-" && _ufno == 1)
            return "";
    }
    if (c == "-" || c == "") {
        if (z == "-" && _ufns == 1) {
            c = "utmccn=(direct)|utmcsr=(direct)|utmcmd=(none)";
        }
        if (c == "-" || c == "")
            return "";
    }
    if (z != "-") {
        i = z.indexOf(".");
        if (i > -1)
            i = z.indexOf(".", i + 1);
        if (i > -1)
            i = z.indexOf(".", i + 1);
        if (i > -1)
            i = z.indexOf(".", i + 1);
        t = z.substring(i + 1, z.length);
        if (t.toLowerCase() == c.toLowerCase())
            cs = 1;
        t = z.substring(0, i);
        if ((i = t.lastIndexOf(".")) > -1) {
            t = t.substring(i + 1, t.length);
            cn = (t * 1);
        }
    }
    if (cs == 0 || _ufns == 1) {
        t = _sGC(dc, "__utma=" + _udh, ";");
        if ((i = t.lastIndexOf(".")) > 9) {
            _uns = t.substring(i + 1, t.length);
            _uns = (_uns * 1);
        }
        cn++;
        if (_uns == 0)
            _uns = 1;
        _ubd.cookie = "__utmz=" + _udh + "." + _ust + "." + _uns + "." + cn + "." + c + "; path=" + _utcp + "; " + x + _udo;
    }
    if (cs == 0 || _ufns == 1)
        return "&utmcn=1";
    else
        return "&utmcr=1";
}
