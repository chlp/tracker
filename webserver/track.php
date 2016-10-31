<?

file_put_contents('tracks/'.time(), json_encode(file_get_contents('php://input')));