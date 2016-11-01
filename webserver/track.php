<?

$json = file_get_contents('php://input');

$data = json_decode($json, true);
if (!$data) {
    return;
}
if (!isset($data['deviceId']) || !isset($data['latitude']) || !isset($data['longitude']) || !isset($data['timestamp'])) {
    return;
}

if (preg_match('/[^-A-Z0-9]/', $data['deviceId'])) {
    return;
}

$dir = "tracks/{$data['deviceId']}";
if (!is_dir($dir)) {
    if (!mkdir($dir, 0777, true)) {
        return;
    }
}

file_put_contents("$dir/" . time(), $json);
