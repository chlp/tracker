<?
$dir = "tracks/21B07E41-22A8-49D6-951B-68B60D3FF61E";
$files = scandir($dir);
$array = array();
foreach($files as $file) {
    if($file == '.') continue;
    if($file == '..') continue;
    $json = file_get_contents("$dir/$file");
    $data = json_decode($json, true);
    if ($data['deviceId'] == '21B07E41-22A8-49D6-951B-68B60D3FF61E') {
        $array[] = array(
                         'latitude' => $data['latitude'],
                         'longitude'=>$data['longitude'],
                         'time'=>date('c', (int)$data['timestamp'])
                         );
    }
}

echo measurementsMap($array);

function measurementsMap($measurements)
{
    $markers = array();
    foreach ($measurements as $measurementInfo) {
        if ((float)$measurementInfo['latitude'] < 0.1 && (float)$measurementInfo['longitude'] < 0.1) {
            continue;
        }
        $markers[] = <<<EOF
        [
        "{$measurementInfo['time']}",
        {$measurementInfo['latitude']},
        {$measurementInfo['longitude']}
        ]
        EOF;
    }
    $markersArrStr = implode(",\r\n", $markers);
    $html = <<<EOF
    <input type="button" value="on map" onclick="initMap()">
    <div id="map" style="display: none; width: 90vw; margin-left: 5vw; height: 80vh;"></div>
    <script type="text/javascript">
    function initMap() {
        var markers = [
        $markersArrStr
        ];
        var myOptions = {
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        mapTypeControl: false
        };
        var mapDiv = document.getElementById("map");
        mapDiv.style.display = 'block';
        var map = new google.maps.Map(mapDiv, myOptions);
        var infowindow = new google.maps.InfoWindow();
        var marker, i;
        var bounds = new google.maps.LatLngBounds();
        for (i = 0; i < markers.length; i++) {
            var pos = new google.maps.LatLng(markers[i][1], markers[i][2]);
            bounds.extend(pos);
            marker = new google.maps.Marker({
                                            position: pos,
                                            map: map
                                            });
            google.maps.event.addListener(marker, 'click', (function(marker, i) {
                                                            return function() {
                                                            infowindow.setContent(markers[i][0]);
                                                            infowindow.open(map, marker);
                                                            }
                                                            })(marker, i));
        }
        map.fitBounds(bounds);
    }
    </script>
    <script async defer src="https://maps.googleapis.com/maps/api/js?key=AIzaSyC-l8wFA45bO7u9YWx5Gkjz02Cw7Ootolg">
    </script>
    EOF;
    return $html;
}
