jQuery(document).ready(function(){
        jQuery("#input").submit(function() {
                var fields = jQuery("#input").serialize();
                jQuery.get("/game/continue", fields, function(data) {
                        jQuery("#"+data.winid).append(data.content);
                        jQuery("#"+data.winid).scrollTop(jQuery("#"+data.winid).height - 400);
                        jQuery('#prompt_type').text(data.input_type);
                        jQuery('#input_type').val(data.input_type);
                    });
                return false;
            });
    });
