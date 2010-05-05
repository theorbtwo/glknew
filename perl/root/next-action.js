jQuery(document).ready(function(){
        jQuery("#input").submit(function() {
                var fields = jQuery("#input").serializeArray();
                jQuery.post("/continue/", fields, function(data) {
                        alert(data);
                    });
                return false;
            });
    });
