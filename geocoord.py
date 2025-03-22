# -*- coding: utf-8 -*-
#! py -3.10
"""
-----------------------------------------------------------
File: geocoord.py
Author: Kelrey, T.
Email: taufiqkelrey1@gmail.com
Github: kelreeeeey
Description: scipt to get city coordinates
-----------------------------------------------------------
"""

import argparse
from geopy.geocoders import Nominatim
import json

def get_coordinates(city_name):
    geolocator = Nominatim(user_agent="city_coordinates_app")
    location = geolocator.geocode(city_name)
    return (location.latitude, location.longitude) if location else None

def get_hemisphere(lat, lon):
    if lat > 0:
        lat = lat
        lat_hemi = "N"
    elif lat < 0:
        lat = lat * -1
        lat_hemi = "S"
    else:
        lat = lat
        lat_hemi = "E"

    if lon > 0:
        lon = lon
        lon_hemi = "E"
    elif lon < 0:
        lon = lon * -1
        lon_hemi = "W"
    else:
        lon = lon
        lon_hemi = "P"

    return {"lat":lat, "latdir":lat_hemi, "long":lon, "longdir":lon_hemi}

def arg_parser():
    parser = argparse.ArgumentParser(
        description="Get coordinates and hemispheres for cities",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "cities", 
        nargs="+",
        help="City names (enclose multi-word cities in quotes)"
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="./cities.json",
        help="Output json file"
    )
    parser.add_argument(
        "-d", "--decimals",
        type=int,
        default=4,
        help="Number of decimal places for coordinates"
    )
    return parser.parse_args()

def main():
    args = arg_parser()

    cities = {"cities":[], "not_found":[]}
    for city in args.cities:
        coords = get_coordinates(city)

        if coords:
            lat, lon = coords
            hemisphere = get_hemisphere(lat, lon)
            data = {"name":city} | hemisphere
            print(f"City: {data}")
            cities['cities'].append(data)
        else:
            print(f"\nCity '{city}' not found")
            cities["not_found"].append(city)

    with open(args.output, "w") as fd:
        json.dump(cities, fd, indent=2, )

if __name__ == "__main__":
    main()
