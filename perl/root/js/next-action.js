jQuery(document).ready(function(){
        jQuery("#input").submit(function() {
                var fields = jQuery("#input").serialize();
                alert(fields);
                jQuery.get("/game/continue", fields, function(data) {
                        alert(data);
                        jQuery("#"+data.winid).append(data.content);
                        jQuery("#"+data.winid).scrollTop(jQuery("#"+data.winid).height - 400);
                    });
                return false;
            });
    });
