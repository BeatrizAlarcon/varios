'use strict';

/* Paradas a mostrar y tiempo estimado en llegar a cada una de ellas desde el INAP */
var busStops = [1924,1925,81,82,83];
var busStopDelays = {
  "1924" : 60,
  "1925" : 60,
  "81" : 120,
  "82" : 180,
  "83" : 120
};
var currentBusStop = 0;

/* Datos de la API */
var cultureInfo = 'es';
var emtApiIdClient = 'XXXXXXXXXXXXXXX';
var emtApiPasskey = 'YYYYYYYYYYYYYYYYYYYY';

/* Función para obtener el tiempo en formato '3 min 20 secs.' */
function secondsToSpanish(seconds){
  var MAX_SECONDS = 999999;
  var SECONDS_PER_MINUTE = 60;
  var retorno;

  if (seconds === MAX_SECONDS) {
    retorno = '+20m';
  } else if (seconds === 0 ){
    retorno = 'En parada.';
  } else if (seconds < SECONDS_PER_MINUTE) {
    retorno = seconds + ' secs.';
  } else {
    var module = seconds % SECONDS_PER_MINUTE;
    var minutes = (seconds - module) / SECONDS_PER_MINUTE;
    retorno = minutes + ' min ' + module + ' secs.';
  }
  return retorno;
}

/* Función para mostrar la imagen correspondiente al autobús pasado por parámetro */
function mostrarElementMapa(elemento){
  /*Es difícil averiguar cual se está mostrando, por lo se ocultan todos*/
  $('.marco-imagenes-paradas-black').hide();
  for (var todos=0;todos < busStops.length;todos++)  {
    $('.marco-imagenes-paradas-' + busStops[todos]).hide();
  }

  /*Muestro el elemento deseado*/
  $('.marco-imagenes-paradas-' + elemento).show();
}

$(document).ready(function() {

  /***********************************************************************************
  * Bucle principal. Rota cada 10 segundos las paradas contenidas en busStops.*
  ************************************************************************************/
  setInterval(function() {

    /* Preparar la llamada a la API */
    var formData = new FormData();
    formData.append('cultureInfo', cultureInfo);
    formData.append('idStop', busStops[currentBusStop]);
    formData.append('idClient', emtApiIdClient);
    formData.append('passKey', emtApiPasskey);

    /*Crear XMLHttpRequest, vincular funciones de callback y enviar petición */
    var XHR = new XMLHttpRequest();

    /* Función de callback si la petición tiene éxito */
    XHR.addEventListener('load', function() {
      var jsonData = JSON.parse(XHR.responseText);

      /* Borrar los autobuses de la parada anterior */
      $('#left-side').empty();

      /* Insertar la cabecera */
      $('#left-side').append('<div class="bus-stop-head-2"><div class="center"><h4 class="text-center">Parada '+ busStops[currentBusStop] +' </h4></div>');

      /* Mostrar los primeros cinco autobuses a los que de tiempo a llegar desde el INAP */
      var busItem =0;
      var numBusesInScreen = 0;
      if ( jsonData.arrives != null ){
        for (busItem; busItem < jsonData.arrives.length; busItem++){

          /* Si da tiempo a coger el autobús y hay espacio */
          if ((jsonData.arrives[busItem].busTimeLeft > busStopDelays[busStops[currentBusStop]])&&(numBusesInScreen<5)){

            /* Mostrar el tiempo del autobús*/
            $('#left-side').append('<li><span class="bus-number">' + jsonData.arrives[busItem].lineId + '</span>' + secondsToSpanish(jsonData.arrives[busItem].busTimeLeft) + '</li>');

            /* Mostrar el elemento del mapa correspondiente */
            mostrarElementMapa(busStops[currentBusStop]);

            numBusesInScreen++;
          }
        }
      } else{
        /* A pesar de que se obtuvo respuesta a la petición, el JSON viene mal formado */
        mostrarElementMapa('black');
      }

      /* Siguiente parada */
      if (currentBusStop === busStops.length -1){
        currentBusStop = 0;
      }else{
        currentBusStop++;
      }

    });

/* Función de callback si la petición fracasa */
XHR.addEventListener('error', function() {
  /*No se recibieron paradas, por lo que se pone a negro el mapa*/
  mostrarElementMapa('black');

  /*Vaciar el contenido de los autobuses*/
  $('#left-side').empty();
});

/* Enviar petición */
XHR.open('POST', 'https://openbus.emtmadrid.es/emt-proxy-server/last/geo/GetArriveStop.php');
XHR.send(formData);

  }, 10000); // <- 5 segundos

});