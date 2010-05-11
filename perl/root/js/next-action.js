
jQuery(document).ready(function(){
        jQuery('#prompt').keydown(function(event) {
                // if key pressed in input box, and in char mode, trigger submit.

                if(jQuery('#prompt_type').text() == 'char') {
                    jQuery('#keycode_input').val(event.which);
                    event.preventDefault;
                    jQuery('#input').submit();
                    return false;
                }
                return true;
            });


        jQuery("form").submit(function() {
                var fields = jQuery(this).serialize();
                jQuery.ajax({ 
                        url: jQuery(this).attr('action'), 
                        data: fields,
                        success: function(data) {
                            jQuery.each(data.windows, function(ind, value) { 
                                    var win_div = jQuery("#"+value.winid);
                                    if(value.status == 'clear') {
                                        win_div.text('');
                                    }
                                    win_div.append(value.content);
                                    //  alert(win_div.height());
                                    
                                    var move_top = win_div.find('span.move-top').last();
                                    win_div.scrollTop(0);
                                    
                                    //alert('pos:' + move_end.position().top + 'offset: ' + move_end.offset().top + 'win off:' + win_div.offset().top);
                                    win_div.scrollTop(move_top.offset().top - win_div.offset().top);
                                });
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
                            alert(textStatus);
                        }
                    });
                return false;
            });
    });
