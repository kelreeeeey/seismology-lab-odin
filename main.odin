package main

import "core:fmt"
import "core:os"
import "core:math"
import "core:strings"
import seis "seismology"

main :: proc() {
    fmt.println("Welcome")

    pagy := seis.Station{
        name="PAGY",
        location="Puerto Ayora, Galapagos Island",
        lat=-0.67,
        long=-90.29,
        distance=25.25,
        azimuth=-137.32,
        time_diff=270.0
    }

    ccm := seis.Station{
        name="CCM",
        location="Cathedral Cave, Missouri, USA",
        lat=38.06,
        long=-91.24,
        distance=22.74,
        azimuth=-26.78,
        time_diff=287.0
    }

    eq := seis.EarthquakeEvent{
        time="2021-08-14 12:29:08 UTC",
        lat=18.4167,
        long=73.4804,
        mag=7.2,
        depth=10,
        source="Haiti Region"
    }

    ambon := seis.Coord_DMS{
        name="Ambon",
        latdir=.S,
        longdir=.E,
        lat={3.0, 41.0, 9.03},
        long={128.0, 13.0, 13.3}
    }

    london := seis.Coord_DMS{
        name="London",
        latdir=.N,
        longdir=.W,
        lat={51.0, 30., 35.5140},
        long={0.0, 7.0, 5.1312}
    }

    coord_ambon := seis.dms_to_decimal(ambon)
    coord_makkah := seis.dms_to_decimal(london)

    seis.calculate_components(&coord_ambon)
    seis.calculate_components(&coord_makkah)

    fmt.printfln("Ambon : %v\n", coord_ambon)
    fmt.printfln("London : %v\n", coord_makkah)

    _, ang_dist := seis.angular_distance_2_points(coord_ambon, coord_makkah)
    ang_dist  = math.to_degrees(ang_dist)
    distance_in_deg := seis.decimal_to_dms(ang_dist)

    fmt.printfln("Angular distance between Ambon-London: %v (%v km)", ang_dist, ang_dist * seis.DEGREE_TO_KM_CONST)
    fmt.printfln("In DMS: %v", distance_in_deg)

    az_backaz := seis.calculate_azimuth_and_back(coord_ambon, coord_makkah)
    fmt.printfln("Azimuth Ambon-London: %v\n", az_backaz)

}
