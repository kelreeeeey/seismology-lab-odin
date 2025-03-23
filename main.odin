package main

import "core:fmt"
import "core:os"
import "core:math"
import "core:strings"
import seis "seismology"

main :: proc() {

    { // Earthquake event in Haiti Region

        fmt.println("Earthquake event in Haiti Region\n========================\n")
        eq := seis.EarthquakeEvent{
            location={
                name="Haiti Region",
                latdir=.N,
                lat=seis.decimal_to_dms(18.4167),
                longdir=.E,
                long=seis.decimal_to_dms(73.4804)
            },
            date={2021, 08, 14},
            time={12, 29, 08, 0},
            mag=7.2,
            depth=10,
        }

        fmt.printfln("Earthquake %v", eq.location.name)
        fmt.printfln("\tWith Mag %v below %v km earth surface", eq.mag, eq.depth)
        fmt.printfln("\tLocation %v%v %v%v",
            seis.dms_to_decimal(eq.location.lat),
            eq.location.latdir,
            seis.dms_to_decimal(eq.location.long),
            eq.location.longdir )
        fmt.printfln("\tAt %v %v UTC\n", eq.date, eq.time)

        pagy := seis.Station{
            name="PAGY",
            location={
                name="Puerto Ayora, Galapagos Island",
                latdir=.S,
                lat=seis.decimal_to_dms(0.67),
                longdir=.W,
                long=seis.decimal_to_dms(90.29)
            },
            distance=25.25,
            azimuth=-137.32,
            time_diff=270.0
        }

        ccm := seis.Station{
            name="CCM",
            location={
                name="Cathedral Cave, Missouri, USA",
                latdir=.N,
                lat=seis.decimal_to_dms(38.06),
                longdir=.W,
                long=seis.decimal_to_dms(91.24)
            },
            distance=22.74,
            azimuth=-26.78,
            time_diff=287.0
        }

        fmt.println("Recorded at:")

        fmt.println("")
        fmt.printfln("1 : Station \t%v", pagy.name)
        fmt.printfln("\t%v", pagy.location.name)
        fmt.printfln("\t\t%v %v", seis.dms_to_decimal(pagy.location.lat), pagy.location.latdir)
        fmt.printfln("\t\t%v %v", seis.dms_to_decimal(pagy.location.long), pagy.location.longdir)
        fmt.printfln("\t%v km from source", pagy.distance)
        fmt.printfln("\t%v degree azimuth w/r source", pagy.azimuth)
        fmt.printfln("\t%v Time difference between event and arrival", pagy.time_diff)

        fmt.println("")
        fmt.printfln("2 : Station \t%v", ccm.name)
        fmt.printfln("\t%v", ccm.location.name)
        fmt.printfln("\t\t%v %v", seis.dms_to_decimal(ccm.location.lat), ccm.location.latdir)
        fmt.printfln("\t\t%v %v", seis.dms_to_decimal(ccm.location.long), ccm.location.longdir)
        fmt.printfln("\t%v km from source", ccm.distance)
        fmt.printfln("\t%v degree azimuth w/r source", ccm.azimuth)
        fmt.printfln("\t%v Time difference between event and arrival", ccm.time_diff)

        fmt.println("")
    }

    { // Calculate distance and azimuth between Ambon and London

        fmt.println("Calculate distance and azimuth between Ambon and London\n========================\n")
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

}
