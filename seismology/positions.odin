package seismology

import "core:fmt"
import "base:intrinsics"
import "core:math"

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


