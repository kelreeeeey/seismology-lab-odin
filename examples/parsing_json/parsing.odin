package test_parsing

import "core:os"
import "core:fmt"
import "core:math"
import seis "../../seismology"

calculate_dist_and_azimuth :: proc(city1: ^seis.Coord_DMS, city2: ^seis.Coord_DMS) {

    coord_city1 := seis.dms_to_decimal(city1^)
    coord_city2 := seis.dms_to_decimal(city2^)

    seis.calculate_components(&coord_city1)
    seis.calculate_components(&coord_city2)

    _, ang_dist := seis.angular_distance_2_points(coord_city1, coord_city2)
    ang_dist  = math.to_degrees(ang_dist)
    distance_in_deg := seis.decimal_to_dms(ang_dist)

    fmt.printfln("Distance between %v-%v: %v (%v km)", coord_city1.name, coord_city2.name, ang_dist, ang_dist * seis.DEGREE_TO_KM_CONST)
    fmt.printfln("In DMS: %v", distance_in_deg)

    az_backaz := seis.calculate_azimuth_and_back(coord_city1, coord_city2)
    fmt.printfln("Azimuth %v-%v: %v", coord_city1.name, coord_city2.name, az_backaz.a_dec)
    fmt.printfln("Back Azimuth %v-%v: %v\n", coord_city1.name, coord_city2.name, az_backaz.ba_dec)

}

main :: proc() {

    args := os.args
    file_name : string
    if len(args) < 2 {
        file_name = "./cities.json"
    } else {
        file_name = args[1]
    }

    fmt.printfln("\nParsing Cities")
    cities, okc1 := seis.parse_json(file_name)
    defer delete_map(cities)
    if okc1 != nil {
        fmt.eprintln(okc1)
    }

    n_records := len(cities)
    city_names := make([]string, n_records)
    defer {
        for value, index in city_names {
            delete_string(value)
        }
        delete(city_names)
    }

    count := 0
    for name, _ in cities {
        city_names[count] = name
        count += 1
        fmt.printfln("record %v: %v", count, name)
    }
    fmt.printfln("\n")

    fmt.printfln("\nCalculate distance between cities")
    for city_a in 0..<n_records {
        for city_b in 0..<n_records {
            if city_a != city_b {
                calculate_dist_and_azimuth(&cities[city_names[city_a]], &cities[city_names[city_b]])
            }
        }
    }

}
