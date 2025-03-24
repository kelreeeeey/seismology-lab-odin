# -*- coding: utf-8 -*-
"""
-----------------------------------------------------------
File: inspecting_sac_data.py
Author: Kelrey, T.
Email: taufiqkelrey1@gmail.com
Github: kelreeeeey
Description: inspecting SAC binary data format
-----------------------------------------------------------
"""

from typing import Any
import struct
from collections import OrderedDict

def parse_sac_header(header_bytes):
    """
    Parse all SAC header fields from a 632-byte header.
    Returns an OrderedDict with field names and values.
    """
    # Determine endianness (little/big-endian)
    delta_le = struct.unpack('<f', header_bytes[0:4])[0]
    endian = '<' if abs(delta_le - 0.05) < 1e-6 else '>'  # Common DELTA check

    header = OrderedDict()

    # --------------------------------------------------
    # Floating Point Header Fields (F-type)
    # --------------------------------------------------
    float_fields = [
        (0, "DELTA"), (1, "DEPMIN"), (2, "DEPMAX"), (4, "ODELTA"),
        (5, "B"), (6, "E"), (7, "O"), (8, "A"),
        (10, "T0"), (11, "T1"), (12, "T2"), (13, "T3"), (14, "T4"),
        (15, "T5"), (16, "T6"), (17, "T7"), (18, "T8"), (19, "T9"),
        (20, "F"), (21, "RESP0"), (22, "RESP1"), (23, "RESP2"), (24, "RESP3"),
        (25, "RESP4"), (26, "RESP5"), (27, "RESP6"), (28, "RESP7"), (29, "RESP8"),
        (30, "RESP9"), (31, "STLA"), (32, "STLO"), (33, "STEL"), (34, "STDP"),
        (35, "EVLA"), (36, "EVLO"), (37, "EVEL"), (38, "EVDP"), (39, "MAG"),
        (40, "USER0"), (41, "USER1"), (42, "USER2"), (43, "USER3"), (44, "USER4"),
        (45, "USER5"), (46, "USER6"), (47, "USER7"), (48, "USER8"), (49, "USER9"),
        (50, "DIST"), (51, "AZ"), (52, "BAZ"), (53, "GCARC"),
        (55, "CMPAZ"), (56, "CMPINC"), (57, "XMINIMUM"), (58, "XMAXIMUM"),
        (59, "YMINIMUM"), (60, "YMAXIMUM"), (54, "DEPMEN")
    ]

    for word, name in float_fields:
        val = struct.unpack(endian + 'f', header_bytes[word*4:(word+1)*4])[0]
        header[name] = val if val != -12345.0 else None

    # --------------------------------------------------
    # Integer Header Fields (N/I-type)
    # --------------------------------------------------
    int_fields = [
        (70, "NZYEAR"), (71, "NZJDAY"), (72, "NZHOUR"), (73, "NZMIN"),
        (74, "NZSEC"), (75, "NZMSEC"), (76, "NVHDR"), (77, "NORID"),
        (78, "NEVID"), (79, "NPTS"), (80, "NWFID"), (81, "NXSIZE"),
        (82, "NYSIZE"), (85, "IFTYPE"), (86, "IDEP"), (87, "IZTYPE"),
        (89, "IINST"), (90, "ISTREG"), (91, "IEVREG"), (92, "IEVTYP"),
        (93, "IQUAL"), (94, "ISYNTH"), (95, "IMAGTYP"), (96, "IMAGSRC"),
        (97, "IBODY")
    ]

    for word, name in int_fields:
        val = struct.unpack(endian + 'i', header_bytes[word*4:(word+1)*4])[0]
        header[name] = val if val != -12345 else None

    # --------------------------------------------------
    # Logical Header Fields (L-type)
    # --------------------------------------------------
    logi_fields = [(105, "LEVEN"), (106, "LPSPOL"), (107, "LOVROK"), (108, "LCALDA")]
    for word, name in logi_fields:
        val = struct.unpack(endian + 'i', header_bytes[word*4:(word+1)*4])[0]
        header[name] = bool(val)  # 0=False, 1=True

    # --------------------------------------------------
    # Alphanumeric Header Fields (K-type)
    # --------------------------------------------------
    # KEVNM (16 characters, words 110-113)
    kevnm = header_bytes[110*4 : 116*4].decode('ascii').strip('\x00 ')
    header["KEVNM"] = kevnm.split('    ')[-1] if kevnm != "-12345" else None

    # Other 8-character K-fields
    k_fields = [
        (110, "KSTNM", 8), (116, "KHOLE", 8), (116, "KO", 8), (116, "KA", 8),
        (122, "KT0", 8), (122, "KT1", 8), (122, "KT2", 8),
        (128, "KT3", 8), (128, "KT4", 8), (128, "KT5", 8),
        (134, "KT6", 8), (134, "KT7", 8), (134, "KT8", 8),
        (140, "KT9", 8), (140, "KF", 8), (140, "KUSER0", 8),
        (146, "KUSER1", 8), (146, "KUSER2", 8), (146, "KCMPNM", 8),
        (152, "KNETWK", 8), (152, "KDATRD", 8), (152, "KINST", 8)
    ]

    for word, name, length in k_fields:
        start = word*4 + k_fields.index((word, name, length)) * 8
        val = header_bytes[start:start+length].decode('ascii').strip('\x00 ')
        header[name] = val if val != "-12345" else None

    return header

def read_file_2(file_name: str) -> (OrderedDict, Any):
    with open(file_name, "rb") as f:
        # Read header (632 bytes)
        header_bytes = f.read(632)  # Read first 632 bytes (header)
        header = parse_sac_header(header_bytes)

        # Print key fields
        print(f"Station: {header['KSTNM']}")
        print(f"Event: {header['KEVNM']}")
        print(f"Sampling Rate: {1/header['DELTA']} Hz")
        print(f"Start Time: {header['B']} seconds")
        print(f"Data Points: {header['NPTS']}")

        # Read data (after header)
        # Parse NPTS (word 79, offset 316 bytes)
        npts = struct.unpack('<i', header_bytes[316:320])[0]  # little-endianf.seek(632)
        data = struct.unpack(f'<{npts}f', f.read(npts * 4))
        print(len(data))
    return header, data

def main() -> None:
    files: list[str] = [
        "./2021-08-14-mww72-haiti-region-35/IU.YSS.00.BH1.M.2021.226.122908.SAC",
        "./2021-08-14-mww72-haiti-region-35/IU.YSS.00.BH2.M.2021.226.122908.SAC",
        "./2021-08-14-mww72-haiti-region-35/IU.YSS.00.BHZ.M.2021.226.122908.SAC",

        "./2021-08-14-mww72-haiti-region-35/IU.PAYG.00.BH1.M.2021.226.122908.SAC",
        "./2021-08-14-mww72-haiti-region-35/IU.PAYG.00.BH2.M.2021.226.122908.SAC",
        "./2021-08-14-mww72-haiti-region-35/IU.PAYG.00.BHZ.M.2021.226.122908.SAC",

    ]
    for file in files:
        header, data = read_file_2(file)
        for name, val in header.items():
            if isinstance(val, (float, int, str)):
                print(name, val, type(val))
        print(data[:20])

    return None

if __name__ == "__main__":
    main()

