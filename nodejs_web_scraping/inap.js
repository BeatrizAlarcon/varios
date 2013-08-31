var request = require('request');
var cheerio = require('cheerio');

var url = 'http://www.inap.es';

request(url, function(err, resp, body) {
        if (err)
            throw err;
        $ = cheerio.load(body);
        var work_string = new String();
        var url = new String();
        var link_text= new String();
        $('#_listcontents_WAR_alfresco_packportlet_INSTANCE_3S0b_contents .list li > div > div').each(function(){
        	 	//console.log($(this).text());
        	 	work_string = ($(this).html());
        	 	//console.log(work_string);

        	 	//console.log(work_string);
        	 	if (work_string.search("<p") != -1){
        	 		//console.log("es un párrafo")
        	 		console.log("---")
        	 		console.log(($(this).text()));
        	 	}else{
        	 		console.log("================");
        	 		var start_position= work_string.search("http://");
        	 		var end_position = work_string.search("\">");
        	 		url = work_string.substring(start_position,end_position);
        	 		
        	 		//Encode special char &
        	 		while ( url.search("&amp;") != -1) {
        	 			url = url.replace("\&amp\;","\&");
        	 		}

        	 		start_position = work_string.search("\">")+2;
        	 		end_position = work_string.search("</a>");
        	 		link_text = work_string.substring(start_position,end_position);

        	 		console.log(link_text);
        	 		console.log(url);
        	 	}
        })
        
});

//http://www.inap.es/inicio?p_p_id=contentviewerservice_WAR_alfresco_packportlet&amp;p_p_lifecycle=0&amp;p_p_state=maximized&amp;p_p_mode=view&amp;p_p_col_id=columna-3&amp;p_p_col_count=1&amp;_contentviewerservice_WAR_alfresco_packportlet_struts_action=%2Fcontentviewer%2Fview&amp;_contentviewerservice_WAR_alfresco_packportlet_nodeName=NOTAINFORMATIVACONVOCATORIA_409944.gcl&amp;contentType=notice
//http://www.inap.es/inicio?p_p_id=contentviewerservice_WAR_alfresco_packportlet&p_p_lifecycle=0&p_p_state=maximized&p_p_mode=view&p_p_col_id=columna-3&p_p_col_count=1&_contentviewerservice_WAR_alfresco_packportlet_struts_action=%2Fcontentviewer%2Fview&_contentviewerservice_WAR_alfresco_packportlet_nodeName=NOTAINFORMATIVACONVOCATORIA_409944.gcl&contentType=notice
