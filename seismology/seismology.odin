package seismology

import "base:intrinsics"
import "core:math"
import "core:fmt"
import "core:time"
import "core:time/datetime"

VP : f64 : 8.1 // -+ 8.1 km/s, speed of V_p
VS : f64 : 4.5 // -+ 4.5 km/s, speed of V_s
CONST_GEOGRAPHIC_TO_GEOCENTRIC :: 0.993277
DEGREE_TO_KM_CONST :: 111.11 // 1^\circl = 111.11 km

Station :: struct {
    name: string,
    location: Coord_DMS,
    distance: f64,
    azimuth: f64,
    time_diff: f64
}

EarthquakeEvent :: struct {
    location: Coord_DMS,
    using date: datetime.Date,
    using time: datetime.Time,
    mag: f32,
    depth: f32,
}

DegMinSec :: struct {
    degree, minute, second: f64
}

LatDir :: enum {
    S, // southern hemisphere
    E, // right in the equator
    N, // norhtern hemisphere
}

LongDir :: enum {
    E, // eastern hemisphere
    P, // Prime meridian
    W, // western hemisphere
}

Quadrants :: enum {
    I,   // 0   - 90  degree
    II,  // 90  - 180 degree
    III, // 180 - 270 degree
    IV,  // 270 - 360 degree
}

Azimuth_BackAzimuth :: struct {
    a_dec: f64,
    a_dms: DegMinSec,
    ba_dec: f64,
    ba_dms: DegMinSec,
    quad: Quadrants
}

Coord_DMS :: struct {
    name: string,
    latdir: LatDir,
    lat: DegMinSec,
    longdir: LongDir,
    long: DegMinSec,
}

Cartesian_Components :: struct {
    a, b, c : f64
}

Coordinate :: struct {
    name: string,
    latdir: LatDir,
    lat: f64,
    longdir: LongDir,
    long: f64,
    geocentric_lat: f64,
    components: Cartesian_Components
}

decimal_to_dms :: proc(degree: $T) -> DegMinSec
where intrinsics.type_is_numeric(T) {

    deg := math.floor(degree)
    min := (degree - deg) * 60.0
    sec := (min - math.floor(min)) * 60.0

    return {degree=deg, minute=min, second=sec}
}

dms_to_decimal_raw :: proc(lat_dms: DegMinSec) -> (lat: f64) {

    lat = ((lat_dms.degree / 1.0) + (lat_dms.minute / 60.0) + (lat_dms.second / 3600.0))

    return lat
}

dms_to_decimal_coor :: proc(coord: Coord_DMS) -> ( out_coor: Coordinate ) {

    out_coor.name = coord.name
    out_coor.latdir = coord.latdir
    out_coor.longdir = coord.longdir

    lat := ((coord.lat.degree / 1.0) + (coord.lat.minute / 60.0) + (coord.lat.second / 3600.0))

    switch out_coor.latdir {
    case .S: out_coor.lat = -lat
    case .N: out_coor.lat = lat
    case .E: out_coor.lat = lat
    }

    out_coor.geocentric_lat = math.to_degrees(math.atan(geographic_to_geocentric(out_coor.lat)))

    long := ((coord.long.degree / 1.0) + (coord.long.minute / 60.0) + (coord.long.second / 3600.0))

    switch out_coor.longdir {
    case .W: out_coor.long = -long
    case .E: out_coor.long = long
    case .P: out_coor.long = long
    }

    return out_coor
}

dms_to_decimal :: proc { dms_to_decimal_raw, dms_to_decimal_coor }
