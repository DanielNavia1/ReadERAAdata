function read_excel(path::AbstractString)

    excel_raw=XLSX.readxlsx(path)

    return excel_raw
    
end
