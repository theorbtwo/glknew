
var Game = {};

jQuery.extend(
  Game,
  {
      scrollBuffers: function() {
          jQuery('.TextBuffer').each( function (ind, tb) {
                  tb = jQuery(tb);
                  var move_top = tb.find('span.move-top').last();
                  tb.scrollTop(0);

                  //alert('pos:' + move_end.position().top + 'offset: ' + move_end.offset().top + 'win off:' + win_div.offset().top);
                  tb.scrollTop(move_top.offset().top - tb.offset().top);
              }
              );
      },
      sendWindowSize: function() {
          jQuery('#all-windows div').each(function(ind, win_div) {
                  var win_id = jQuery(win_div).attr('id');
                  if (!win_id) {
                    return;
                  }
                  var fields = { win_id: win_id,
                                 game_id: jQuery('input[name~=game_id]:first').val(),
                                 width: jQuery(win_div).width(),
                                 height: jQuery(win_div).height()
                  };
                  jQuery.ajax(
                    {
                        url: '/ajax/window_size',
                        data: fields,
                        success: function() {},
                        error: function(XMLHttpRequest, textStatus, errorThrown) {
                          alert(XMLHttpRequest.responseText);
                        }
                    });

              });
      }
  }
);

jQuery(document).ready(
  function(){
    Game.sendWindowSize();
    jQuery('#prompt').keydown(
      function(event) {
        // if key pressed in input box, and in char mode, trigger submit.

        if(jQuery('#prompt_type').text() == 'char') {
          jQuery('#keycode_input').val(event.which);
          jQuery('#keycode_ident').val(event.keyIdentifier);

          jQuery('#input').submit();
          return false;
        }
        return true;
      });


    jQuery("form").submit(
      function() {
        jQuery('#throbber').show();
        jQuery('#status').text('Sending...');

        var fields = jQuery(this).serialize();
        jQuery.ajax(
          {
            url: jQuery(this).attr('action'),
            data: fields,
            success: function(data) {
              if (!data) {
                jQuery('#status').text('success with empty data?');
                jQuery('#throbber').hide();
                alert("Empty response?");
                return;
              }

              jQuery('#throbber').hide();
              jQuery('#status').text('');

              // On redraw, windows is a string, now an array!!
              if(data.redraw) {
                  jQuery('#all-windows').html(data.windows);
                  Game.sendWindowSize();
              } else {
                  jQuery.each(data.windows,
                              function(ind, value) {
                                  var win_div = jQuery("#"+value.winid);
                                  if(!win_div.length) return;
                                  if(value.status == 'clear') {
                                      win_div.text('');
                                  }
                                  win_div.append(value.content);
                                  //  alert(win_div.height());

                              });
              }
              Game.scrollBuffers();
                  // { save => 1, input => 0} display state of forms
              var key;
              for (key in data.show_forms) {
                if(typeof data.show_forms[key] !== 'function') {
                  if(data.show_forms[key] == 1) {
                    jQuery('#' + key).show();
                  } else {
                    jQuery('#' + key).hide();
                  }
                }
              }
              jQuery('#prompt_type').text(data.input_type);
              jQuery('#input_type').val(data.input_type);
              jQuery('#prompt').val('');
              jQuery('#keycode_input').val('');
            },
            dataType: 'json',
            error: function(XMLHttpRequest, textStatus, errorThrown) {
              alert(XMLHttpRequest.responseText);
            }
          });
        return false;
      });
  });
