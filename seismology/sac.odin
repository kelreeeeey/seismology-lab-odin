package seismology

import "base:runtime"
import "base:intrinsics"

import "core:fmt"
import "core:os"
import "core:io"
import "core:bufio"
import "core:mem"
import "core:c"
import "core:strings"
import "core:strconv"
import "core:encoding/endian"

ReadFileError :: union {
    OpenError,
    ReaderCreationError,
    ReaderReadByteError,
    mem.Allocator_Error,

    InvalidFormatError,

    // SAC Headers Error
    InvalidHeaderError,
    InvalidVersionError,
    InvalidHeaderLengthError,
    ParseError,
}

InvalidFormatError :: struct {
    file_name: string,
    message:   string
}

OpenError :: struct {
    file_name: string,
    error: os.Errno,
}

ReaderCreationError :: struct {
    file_name: string,
    stream: io.Stream,
}

ReaderReadByteError :: struct {
    file_name: string,
    reader: bufio.Reader,
}

InvalidHeaderError :: struct {
    message: string,
}

InvalidVersionError :: struct {
    message: string,
    version: [2]u8,
}

InvalidHeaderLengthError :: struct {
    message: string,
    length: [2]u8,
}

ParseSACHeaderError :: enum {
    None,
    Invalid_Descriptor,
    Malformed_Header,
    Shape_Parse_Failed,
}

// SAC Headers

BIT_SIZE :: 4
HEADER_SIZE :: 632 // total header size

NaN_Float  :: -12345.0
NaN_Int    :: -12345
NaN_String :: "-12345"

SAC_Header_FloatField :: struct {
    delta:                             f32, // Increment between evenly spaced samples (nominal value). [required]
    depmin:                            f32, // Minimum value of dependent variable
    depmax:                            f32, // Maximum value of dependent variable
    odelta:                            f32, // Observed increment if different from nominal value
    b:                                 f32, // Beginning value of the independent variable. [required]
    e:                                 f32, // Ending value of the independent variable. [required]
    o:                                 f32, // Event origin time (seconds relative to reference time)
    a:                                 f32, // First arrival time (seconds relative to reference time)
    t0, t1, t2, t3, t4:                f32, // User defined time picks or markers (seconds relative to reference time)
    t5, t6, t7, t8, t9:                f32, // User defined time picks or markers (seconds relative to reference time)
    f:                                 f32, // Fini or end of event time (seconds relative to reference time)

    // Instrument response parameters [not currently used]
    resp0, resp1, resp2, resp3:        f32,
    resp4, resp5, resp6, resp7, resp8: f32,
    resp9:                             f32,

    stla:                              f32, // Station latitude (degrees, north positive)
    stlo:                              f32, // Station longitude (degrees, east positive)
    stel:                              f32, // Station elevation above sea level (meters) [not currently used]
    stdp:                              f32, // Station depth below surface (meters) [not currently used]
    evla:                              f32, // Event latitude (degrees, north positive)
    evlo:                              f32, // Event longitude (degrees, east positive)
    evel:                              f32, // Event elevation (meters) [not currently used]
    evdp:                              f32, // Event depth below surface (kilometers)
    mag:                               f32, // Event magnitude

    // User defined variable storage
    user0, user1, user2, user3, user4: f32,
    user5, user6, user7, user8, user9: f32,

    dist:                              f32, // Station to event distance (km)
    az:                                f32, // Event to station azimuth (degrees)
    baz:                               f32, // Station to event azimuth (degrees)
    gcarc:                             f32, // Station to event great circle arc length (degrees)
    cmpaz:                             f32, // Component azimuth (degrees clockwise from north)
    cmpinc:                            f32, // Component incident angle (degrees from upward vertical)
    xminimum:                          f32, // Minimum value of X (Spectral files only)
    xmaximum:                          f32, // Maximum value of X (Spectral files only)
    yminimum:                          f32, // Minimum value of Y (Spectral files only)
    ymaximum:                          f32, // Maximum value of Y (Spectral files only)
    depmen:                            f32, // Mean value of dependent variable
}

SAC_Header_IntField :: struct {
    nzyear:   i32, // GMT year
    nzjday:   i32, // GMT Julian day
    nzhour:   i32, // GMT hour
    nzmin:    i32, // GMT minute
    nzsec:    i32, // GMT second
    nzmsec:   i32, // GMT millisecond
    //nvhdr:    i32, // Header version (6/7) [required]
    norid:    i32, // Origin ID
    nevid:    i32, // Event ID
    npts:     i32, // Number of points [required]
    nwfid:    i32, // Waveform ID
    nxsize:   i32, // Spectral length
    nysize:   i32, // Spectral width
    iftype:   i32, // File type [required]
    idep:     i32, // Dependent variable type
    iztype:   i32, // Reference time type
    iinst:    i32, // Instrument type
    istreg:   i32, // Station region
    ievreg:   i32, // Event region
    ievttyp:  i32, // Event type
    iqual:    i32, // Data quality
    isynth:   i32, // Synthetic flag
    imagtyp:  i32, // Magnitude type
    imagsrc:  i32, // Magnitude source
    ibody:    i32, // Spheroid definition
}

//SAC_Header_EnumField :: struct {
//    idep:   i32,
//    iztype: i32,
//    nsnpts: i32
//}

SAC_Header_BoolField :: struct {
    leven:    bool, // Evenly spaced data [required]
    lpspol:   bool, // Positive polarity
    lovrok:   bool, // Overwrite OK
    lcalda:   bool, // Calculate distances
}

SAC_Header_StringField :: struct {
    kstnm:    string,                                 // Station name (8)
    kevnm:    string,                                 // Event name (16)
    khole:    string,                                 // Hole identifier (8)
    ko:       string,                                 // Origin ID (8)
    ka:       string,                                 // Arrival ID (8)
    kt0:      string, kt1: string, kt2: string,       // Time picks (8 each)
    kt3:      string, kt4: string, kt5: string,       // Time picks (8 each)
    kt6:      string, kt7: string, kt8: string,       // Time picks (9 each)
    kt9:      string,                                 // Time pick (8)
    kf:       string,                                 // Fini ID (8)
    kuser0:   string, kuser1: string, kuser2: string, // User strings (8 each)
    kcmpnm:   string,                                 // Channel name (8)
    knetwk:   string,                                 // Network name (8)
    kdatrd:   string,                                 // Read date (8)
    kinst:    string,                                 // Instrument name (8)
}

NVHDR :: enum {
    NVHDR6,
    NVHDR7,
}

SAC_Header :: struct {
    nvhdr:               NVHDR,                     // number-version-header either 6 or 7
    using float_fields:  SAC_Header_FloatField,
    using int_fields:    SAC_Header_IntField,
    using string_fields: SAC_Header_StringField,
    using bool_fields:   SAC_Header_BoolField,
    //using enum_fields:   SAC_Header_EnumField
}

SAC_File :: struct {
    header: SAC_Header,
    data: [dynamic]f64
}

delete_data :: proc(h: ^SAC_File) {
    delete (h.data)
}

load_sac :: proc(
    file_name : string,
    allocator := context.temp_allocator) -> (

    sac_file: SAC_File,
    error: ReadFileError
) {

    handle, open_err := os.open(file_name, os.O_RDONLY)
    if open_err != os.ERROR_NONE {
        fmt.printfln("Failed to open %v with err: %v", file_name, open_err)
        return sac_file, OpenError{file_name, open_err}
    }

    stream := os.stream_from_handle(handle)

    reader, ok := io.to_reader(stream)
    if !ok {
        fmt.printfln("Failed make reader of %v with err: %v", file_name, ok)
        return sac_file, ReaderCreationError{file_name, stream}
    }

    bufio_reader : bufio.Reader
    bufio.reader_init(&bufio_reader, reader, 1600, allocator)

    ok_parsed := parse_header(&sac_file, reader, allocator=allocator)
    if !ok_parsed {
        return sac_file, InvalidFormatError{file_name=file_name, message="Header is not valid"}
    }

    //if reader,  < 632 {
    //    msg: string = "File is not in a valid SAC format"
    //    fmt.println(msg)
    //    return sac_file, InvalidFormatError{file_name=file_name, message=msg}
    //}


    return sac_file, nil
}

parse_header :: proc(sac_file: ^SAC_File, reader: io.Reader, allocator:= context.allocator) -> (error: bool) {

    header_bytes := make([]byte, HEADER_SIZE)
    {
        read, rerr := io.read(reader, header_bytes[:])
        if rerr != nil || read != HEADER_SIZE {
            return false
        }
    }

    return true
}

