/*** FUNCIONES DE COLOR PICKER
 *
 **/
function getPosition(obj){
    var left = 0;
    var top = 0;
    
    while (obj.offsetParent) {
        left += obj.offsetLeft;
        top += obj.offsetTop;
        obj = obj.offsetParent;
    }
    left += obj.offsetLeft;
    top += obj.offsetTop;
    
    return {
        x: left,
        y: top
    };
}


function mouseCoordinates(ev){
    ev = ev || window.event;
    if (ev.pageX || ev.pageY) 
        return {
            x: ev.pageX,
            y: ev.pageY
        };
    return {
        x: ev.clientX + document.body.scrollLeft - document.body.clientLeft,
        y: ev.clientY + document.body.scrollTop - document.body.clientTop
    };
}


function cpMouseClick(ev){
    ev = ev || window.event;
    var mousePos = mouseCoordinates(ev);
    
    var cpPos = getPosition(this);
    var x = mousePos.x - cpPos.x - 1; // 1.41 == 360 / 255
    var y = mousePos.y - cpPos.y - 1;
    this.parentNode.parentNode.getElementsByTagName('INPUT')[0].value = Math.round(x * 1.41);
    
    this.parentNode.className = 'hidden';
    $j('#' + this.parentNode.id.replace('selector', 'preview')).css('background', hsv2rgb(Math.round(x * 1.41), 100, 100));
}

function hsv2rgb(h, s, v){
    r, g, b = hsv2rgbcore(h, s, v);
    
    r = Math.round(r * 255);
    g = Math.round(g * 255);
    b = Math.round(b * 255);
    return '#' + Int2Hex(r) + Int2Hex(g) + Int2Hex(b);
}

function hsv2rgb(h, s, v){
    var rgb = [];
    if (h == 360) {
        h = 0;
    }
    s /= 100;
    v /= 100;
    var r = null;
    var g = null;
    var b = null;
    if (s == 0) {
        // color is on black-and-white center line
        // achromatic: shades of gray
        r = v;
        g = v;
        b = v;
    }
    else {
        // chromatic color
        var hTemp = h / 60; // h is now IN [0,6]
        var i = Math.floor(hTemp); // largest integer <= h
        var f = hTemp - i; // fractional part of h
        var p = v * (1 - s);
        var q = v * (1 - (s * f));
        var t = v * (1 - (s * (1 - f)));
        
        switch (i) {
            case 0:
                r = v;
                g = t;
                b = p;
                break;
            case 1:
                r = q;
                g = v;
                b = p;
                break;
            case 2:
                r = p;
                g = v;
                b = t;
                break;
            case 3:
                r = p;
                g = q;
                b = v;
                break;
            case 4:
                r = t;
                g = p;
                b = v;
                break;
            case 5:
                r = v;
                g = p;
                b = q;
                break;
        }
    }
    r = Math.round(r * 255);
    g = Math.round(g * 255);
    b = Math.round(b * 255);
    return '#' + Int2Hex(r) + Int2Hex(g) + Int2Hex(b);
}

function Int2Hex(strNum){
    base = strNum / 16;
    rem = strNum % 16;
    base = base - (rem / 16);
    baseS = MakeHex(base);
    remS = MakeHex(rem);
    return baseS + '' + remS;
}

function MakeHex(x){
    if ((x >= 0) && (x <= 9)) {
        return x;
    }
    else {
        switch (x) {
            case 10:
                return "A";
            case 11:
                return "B";
            case 12:
                return "C";
            case 13:
                return "D";
            case 14:
                return "E";
            case 15:
                return "F";
        }
    }
}