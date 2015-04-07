#
# misc.jl --
#
# Implement reading/writing of FITS data from/to FITS files.
#
#------------------------------------------------------------------------------
#
# This file is part of OIFITS.jl which is licensed under the MIT "Expat"
# License:
#
# Copyright (C) 2015, Éric Thiébaut.
#
#------------------------------------------------------------------------------

using FITSIO
import FITSIO: TableHDU, AsciiHDU
import Base: read

const _EXTENSION = ["IMAGE" => :image_hdu,
                    "TABLE" => :ascii_table,
                    "BINTABLE" => :binary_table]

# Guess HDU type (no warranty to work for primary HDU nor for incomplete
# header).
function get_hdutype(hdr::FITSHeader)
    if haskey(hdr, "XTENSION")
       return get(_EXTENSION, uppercase(rstrip(hdr["XTENSION"])), :unknown)
    elseif haskey(hdr, "SIMPLE") && hdr["SIMPLE"] == true
        return :image_hdu
    else
        return :unknown
    end
end

# Low level version.
function readtable(ff::FITSFile)
    hdr = readheader(ff) # This also make sure FITS file is open.
    hdutype = get_hdutype(hdr)
    if hdutype != :binary_table && hdutype != :ascii_table
        error("this FITS HDU does not contain a table")
    end
    data = Dict{ASCIIString,Any}()
    ncols = oifits_get_integer(hdr, "TFIELDS", 0) # FIXME:
    for k in 1:ncols
        name = uppercase(strip(oifits_get_string(hdr, "TTYPE$k", ""))) # FIXME:
        if haskey(data, name)
            warn("duplicate column name: \"$name\"")
            continue
        end
        data[name] = oifits_read_column(ff, k) # FIXME:
        units = strip(oifits_get_string(hdr, "TUNIT$k", "")) # FIXME:
        if length(units) > 0
            data[name*".units"] = units
        end
    end
    return data
end

# Read the entire table from disk. (High level version.)
function read(hdu::Union(TableHDU,AsciiHDU))
    readtable(hdu.fitsfile)
end

# Local Variables:
# mode: Julia
# tab-width: 8
# indent-tabs-mode: nil
# fill-column: 79
# coding: utf-8
# ispell-local-dictionary: "american"
# End: