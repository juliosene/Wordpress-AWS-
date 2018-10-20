#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.
#    if (client.ip != "127.0.0.1" && req.http.host ~ "##HTTPSSERVERNAME##") {
#	set req.http.x-redir = "http://##HTTPSSERVERNAME##" + req.url;
#	return(synth(850, ""));
#    }

    if (req.method == "PURGE") {
	if (!client.ip ~ purger) {
	    return(synth(405, "This IP is not allowed to send PURGE requests."));
	}
	    return (purge);
    }

    if (req.restarts == 0) {
	if (req.http.X-Forwarded-For) {
	    set req.http.X-Forwarded-For = client.ip;
	}
    }
    if (req.http.Authorization || req.method == "POST") {
	return (pass);
    }

    if (req.url ~ "/feed") {
	return (pass);
    }
    if (req.url ~ "wp-admin|wp-login") {
	return (pass);
    }

    set req.http.cookie = regsuball(req.http.cookie, "wp-settings-\d+=[^;]+(; )?", "");
    set req.http.cookie = regsuball(req.http.cookie, "wp-settings-time-\d+=[^;]+(; )?", "");
    if (req.http.cookie == "") {
	unset req.http.cookie;
    }

}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.
    
    set beresp.ttl = 24h;
    set beresp.grace = 1h;

    if (beresp.http.content-type ~ "text") {
        set beresp.do_gzip = true;
    }
    if (bereq.url !~ "wp-admin|wp-login|product|cart|checkout|my-account|/?remove_item=") {
	unset beresp.http.set-cookie;
    }
       
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
    if (req.http.X-Purger) {
	set resp.http.X-Purger = req.http.X-Purger;
    }

}

sub vcl_synth {
    if (resp.status == 850) {
        set resp.http.Location = req.http.x-redir;
        set resp.status = 302;
        return (deliver);
    }
}

sub vcl_purge {
    set req.method = "GET";
    set req.http.X-Purger = "Purged";
    return (restart);
}

acl purger {
   "localhost";
}
