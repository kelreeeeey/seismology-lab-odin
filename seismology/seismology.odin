package seismology

import "base:intrinsics"
import "core:math"
import "core:fmt"

VP : f64 : 8.1 // -+ 8.1 km/s, speed of V_p
VS : f64 : 4.5 // -+ 4.5 km/s, speed of V_s
CONST_GEOGRAPHIC_TO_GEOCENTRIC :: 0.993277
DEGREE_TO_KM_CONST :: 111.11 // 1^\circl = 111.11 km

Station :: struct {
    name: string,
    location: string,
    lat: f64,
    long: f64,
    distance: f64,
    azimuth: f64,
    time_diff: f64
}

EarthquakeEvent :: struct {
    time: string,
    lat: f64,
    long: f64,
    mag: f32,
    depth: f32,
    source: string
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

dms_to_decimal :: proc(coord: Coord_DMS) -> ( out_coor: Coordinate ) {

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

calculate_components :: proc(coord: ^Coordinate) {

    coord.components.a = math.cos(math.to_radians(coord.long)) * math.cos(math.to_radians(coord.geocentric_lat))

    coord.components.b = math.sin(math.to_radians(coord.long)) * math.cos(math.to_radians(coord.geocentric_lat))

    coord.components.c = math.sin(math.to_radians(coord.geocentric_lat))

}

geographic_to_geocentric :: proc(lat: $T) -> T
where intrinsics.type_is_numeric(T) {

    conv := math.tan(math.to_radians(lat)) * CONST_GEOGRAPHIC_TO_GEOCENTRIC
    return conv

}

geocentric_to_geographic :: proc(lat: $T) -> T
where intrinsics.type_is_numeric(T) {

    conv := math.tan(math.to_radians(lat)) / CONST_GEOGRAPHIC_TO_GEOCENTRIC
    return conv

}

angular_distance_2_points :: proc(epicenter, source: Coordinate) -> ( cosine_ang, ang_dist:f64 ) {

    cosine_ang  = epicenter.components.a * source.components.a
    cosine_ang += epicenter.components.b * source.components.b
    cosine_ang += epicenter.components.c * source.components.c
    ang_dist = math.acos(cosine_ang)

    return cosine_ang, ang_dist
}

calculate_azimuth_and_back :: proc(epicenter, station: Coordinate) -> (az: Azimuth_BackAzimuth) {

    cosine_ang, cos_ang_dist := angular_distance_2_points(epicenter, station)
    cos_ang_dist = math.to_degrees(cos_ang_dist)
    sin_ang_dist := math.sin(math.to_radians(cos_ang_dist))

    sin_Aes : type_of(sin_ang_dist)
    sin_Bes : type_of(sin_ang_dist)
    cos_Aes : type_of(sin_ang_dist)

    { // calulate azimuth
        sin_Aes = math.sin(math.to_radians(station.long - epicenter.long)) * math.sin(math.to_radians(90-station.geocentric_lat))
        sin_Aes /= sin_ang_dist
        sin_Aes  = math.to_degrees(math.asin(sin_Aes))

        cos_Aes = math.cos(math.to_radians(90.0 - station.geocentric_lat)) - (cosine_ang * math.cos(math.to_radians(90-epicenter.geocentric_lat)))
        cos_Aes /= math.sin(math.to_radians(cos_ang_dist)) * math.sin(math.to_radians(90-epicenter.geocentric_lat))
        cos_Aes  = math.to_degrees(math.acos(cos_Aes))

    }

    { // calulate back azimuth
        sin_Bes = math.sin(math.to_radians(epicenter.long - station.long)) * math.sin(math.to_radians(90-epicenter.geocentric_lat))
        sin_Bes /= sin_ang_dist
        sin_Bes  = math.to_degrees(math.asin(sin_Bes))

    }

    a_dec := math.abs(sin_Aes)
    if sin_Aes > 0 {
        if cos_Aes > 0 {
            az.quad = .I
            az.a_dec = a_dec
        } else {
            az.quad = .IV
            az.a_dec = 360.0 - a_dec
        }
    } else {
        if cos_Aes > 0 {
            az.quad = .II
            az.a_dec = 180.0 - a_dec
        } else {
            az.quad = .III
            az.a_dec = 180.0 + a_dec
        }
    }
    az.a_dms = decimal_to_dms(az.a_dec)

    az.ba_dec = 180.0 - sin_Bes
    az.ba_dms = decimal_to_dms(az.ba_dec)

    return az
}




