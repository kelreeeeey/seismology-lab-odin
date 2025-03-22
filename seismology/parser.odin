package seismology

import "core:os"
import "core:fmt"
import "core:encoding/json"

//parse_dms :: proc(s: string) -> (dms: DegMinSec, dir: rune) {
//    // Split into numerical part and direction
//    dir = rune(s[len(s)-1]) // Last character is the direction (N/S/E/W)
//    parts_str := s[:len(s)-1] // Remove the direction
//
//    // Split D°M'S.S" into components
//    parts := strings.split(parts_str, "°")
//    defer delete(parts)
//
//    if len(parts) >= 1 {
//        dms.degree = strconv.parse_f64(parts[0]) or_else 0.0
//
//        if len(parts) >= 2 {
//            minutes_seconds := strings.split(parts[1], "'")
//            defer delete(minutes_seconds)
//
//            if len(minutes_seconds) >= 1 {
//                dms.minute = strconv.parse_f64(minutes_seconds[0]) or_else 0.0
//
//                if len(minutes_seconds) >= 2 {
//                    seconds := strings.trim_right(minutes_seconds[1], "\"")
//                    dms.second = strconv.parse_f64(seconds) or_else 0.0
//                }
//            }
//        }
//    }
//    return
//}

//parse_coord :: proc(json_str: string) -> (coord: Coord_DMS, err: bool) {
//    // Parse into temporary JSON structure
//    Temp :: struct {
//        name:  string,
//        coord: Maybe(string),
//        lat:   Maybe(string),
//        long:  Maybe(string),
//    }
//
//    temp: Temp
//    if !json.unmarshal(json_str, &temp) {
//        return {}, true
//    }
//
//    coord.name = temp.name
//
//    // Handle both JSON formats
//    lat_str, long_str: string
//    if temp.coord != nil {
//        // Split "3°41'09.3\"S 128°13'13.3\"E" into lat/long
//        coord_parts := strings.split(temp.coord.(string), " ")
//        defer delete(coord_parts)
//        if len(coord_parts) != 2 do return {}, true
//        lat_str, long_str = coord_parts[0], coord_parts[1]
//    } else {
//        if temp.lat == nil || temp.long == nil do return {}, true
//        lat_str, long_str = temp.lat.(string), temp.long.(string)
//    }
//
//    // Parse latitude
//    lat_dms, lat_dir := parse_dms(lat_str)
//    coord.lat = lat_dms
//    coord.latdir = lat_dir == 'N' ? .N : .S
//
//    // Parse longitude
//    long_dms, long_dir := parse_dms(long_str)
//    coord.long = long_dms
//    coord.longdir = long_dir == 'E' ? .E : .W
//
//    return coord, false
//}


ParseError :: union {
    os.Error,
    json.Error,
    ReadFileError,
}

ReadFileError :: struct {
    massage: string
}

parse_json :: proc(filename: string) -> (cities: map[string]Coord_DMS, parse_err: ParseError) {

    data, ok := os.read_entire_file_from_filename(filename)
    if !ok {
        fmt.eprintln("Failed to load the file!")
        return nil, ReadFileError{massage="Reading file error"}
    }
    defer delete(data) // Free the memory at the end

    settings: Coord_DMS

    json_data, err := json.parse(data)
    if err != .None {
        fmt.eprintln("Failed to parse the json file.")
        fmt.eprintln("Error:", err)
        return nil, err
    }
    defer json.destroy_value(json_data)

    root := json_data.(json.Object)
    cities_json := root["cities"].(json.Array)
    n_records := len(cities_json)

    cities = make(map[string]Coord_DMS)

    for idx in 0..< n_records {

        city_json := cities_json[idx].(json.Object)

        city : Coord_DMS
        city.name = city_json["name"].(json.String)

        latdir := city_json["latdir"].(json.String)
        longdir := city_json["longdir"].(json.String)

        if latdir == "N" {
            city.latdir = .N
        } else if latdir == "S" {
            city.latdir = .S
        } else {
            city.latdir = .E
        }

        if longdir == "E" {
            city.longdir = .E
        } else if longdir == "W" {
            city.longdir = .W
        } else {
            city.longdir = .P
        }

        city.lat = decimal_to_dms(city_json["lat"].(json.Float))
        city.long = decimal_to_dms(city_json["long"].(json.Float))

        cities[city.name] = city
        
    }

    return cities, nil

}
