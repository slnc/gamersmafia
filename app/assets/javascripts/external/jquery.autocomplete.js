/**
* WARNING: Customized for Gamersmafia, this is not the stock autocomplete
* anymore.
*
* Json key/value autocomplete for jQuery
* Provides a transparent way to have key/value autocomplete
* Copyright (C) 2008 Ziadin Givan www.CodeAssembly.com
*               2012 Juan Alonso
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with this program.  If not, see http://www.gnu.org/licenses/
*
* Examples
*    // using default parameters
*	   $("input#example").autocomplete("autocomplete.php");
*
*    // custom params
*	   $("input#example").autocomplete("autocomplete.php",{
*	       minChars:3,
*	       timeout:3000,
*	       validSelection:false,
*	       click_fn: function(li, textInput) { $(this).doSomething()},
*	       parameters: {'myparam': 'myvalue'},
*	       before: function(input, text, settings) {},
*	       after : function(input,text) {},
*	   });
*
* minChars = Minimum characters the input must have for the ajax request to be made
*	timeOut = Number of miliseconds passed after user entered text to make the ajax request
* validSelection = If set to true then will invalidate (set to empty) the
*                  value field if the text is not selected (or modified) from
*                  the list of items.
* parameters = Custom parameters to be passed
* after, before = a function that will be caled before/after the ajax request
* click_fn = function to call on selection from autocompletion
*/
jQuery.fn.autocomplete = function(url, settings) {
	return this.each(function() { //do it for each matched element
		// this is the original input
		var textInput = $(this);
    // We need to make sure the autocomplete is visible to get its coords.
    var wasHidden = $(this).is(':hidden');
    if (wasHidden) {
      $(this).show();
    }
    // create a new hidden input that will be used for holding the return value
    // when posting the form, then swap names with the original input.
		textInput.after(
      '<input type=hidden name="' + textInput.attr("name") + '"/>')
      .attr("name", textInput.attr("name") + "_text");
		var valueInput = $(this).next();
		// create the ul that will hold the text and values
		valueInput.after('<ul class="autocomplete user-input"></ul>');
		var list = valueInput.next().css({
      top: textInput.offset().top + textInput.outerHeight(),
      left: textInput.offset().left,
      width: 'auto'
    }).hide();
    if (wasHidden) {
      $(this).hide();
    }
		var oldText = '';
		var typingTimeout;
		var size = 0;
		var selected = 0;

		settings = jQuery.extend({
			minChars : 1,
			timeout: 1000,
			after : null,
			before : null,
			validSelection : true,
      click_fn: function (li, textInput) {
        var valueInput = textInput.next();
        valueInput.val($(li).attr('value') );
        textInput.val($(li).text());
        clear();
      },
			parameters : {
          'inputName' : valueInput.attr('name'),
          'inputId' : textInput.attr('id')}
		}, settings);

		function getData(text) {
			window.clearInterval(typingTimeout);
			if (text != oldText &&
          (settings.minChars != null && text.length >= settings.minChars)) {
				clear();
				if (settings.before) {
					settings.before(textInput, text, settings);
				}
				textInput.addClass('autocomplete-loading');
				settings.parameters.text = text;
				$.getJSON(url, settings.parameters, function(data) {
					var items = '';
					if (data) {
            $.each(data, function(key, val) {
              items += '<li value="' + key + '">' + val + '</li>';
            });
            list.html(items);

            // on mouse hover over elements set selected class and on click
            // set the selected value and close list
            list.show().children()
              .hover(function() {
                $(this).addClass("selected").siblings().removeClass("selected");
              }, function() {
                $(this).removeClass("selected")
              })
              .click(function(e) {
                settings.click_fn(e.currentTarget, textInput);
              });

						if (settings.after == "function") {
							settings.after(textInput,text);
						}
					}
					textInput.removeClass('autocomplete-loading');
				});
				oldText = text;
			}
		}

		function clear() {
			list.hide();
			size = 0;
			selected = 0;
		}

		textInput.keydown(function(e) {
      if (e.which == 13) { // enter
        return false;
      }
    });

		textInput.keyup(function(e) {
      size = list.children().size();
			window.clearInterval(typingTimeout);
			if (e.which == 27) { //escape
				clear();
			} else if (e.which == 46 || e.which == 8) { // delete and backspace
        if (textInput.val() == "") {
          clear();
        }
        getData(textInput.val());
				// invalidate previous selection
				if (settings.validSelection) {
          // valueInput.val('');
        }
			} else if (e.which == 13) { // enter
				if (list.css("display") == "none") { 
          // if the list is not visible then make a new request, otherwise hide the list
					getData(textInput.val());
        } else {
          settings.click_fn(
            list.children().removeClass('selected').eq(selected).addClass('selected'), textInput);
          clear();
        }
				e.preventDefault();
				e.stopPropagation();
				return false;

			} else if (e.which == 40 || e.which == 9 || e.which == 38) { //move up, down
			  switch(e.which) {
				case 40: // down
				case 9:
				  selected = (selected >= size - 1) ? 0 : selected + 1;
          break;

				case 38:  // up
				  selected = (selected <= 0) ? size - 1 : selected - 1;
          break;

				default:
          break;
			  }

        list.children().removeClass('selected').eq(selected)
          .addClass('selected');
			} else { // invalidate previous selection
				if (settings.validSelection) {
        }
				typingTimeout = window.setTimeout(
            function() {
              getData(textInput.val())
            },
            settings.timeout);
			}
		});
	});
};
