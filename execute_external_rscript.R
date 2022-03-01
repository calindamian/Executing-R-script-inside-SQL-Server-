#' Alternative of SQL Server sp_execute_external_script to allow mixing of SQL and R language
#' Author: Calin Damian


#libraries
library(tidyverse)
library(rlang) 
library(DBI)


#common functions
export_table = function (   conn , 
                            output_folder ,
                            output_table ,
                            fmt_file = "fmt_temp.xml" ,
                            colsep = ";" ,
                            rowsep = "\\\\n" ,
                            first_row = 2 ,
                            code_page = 65001
                            
) {
  
  data_file = str_c(output_folder ,output_table, '.csv' )
  
  tb_raw = read_delim(data_file , delim = colsep , n_max = 0)  %>%
    as_tibble()
  
  xml_pattern = 
    str_c( '<?xml version="1.0"?>
  <BCPFORMAT xmlns="http://schemas.microsoft.com/sqlserver/2004/bulkload/format" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <RECORD>' , '\n#inputcols#' , '\n</RECORD>' , '\n<ROW>' , '\n#outputcols#' , '\n</ROW>\n</BCPFORMAT>'  )
  
  
  tibble(col_names=  tb_raw %>%names() ) %>%
    mutate( last_row = row_number() == nrow(.) ,
            seplast = if_else(last_row ,  rowsep , colsep) ,
            inputcols = str_c('<FIELD ID="' , col_names ,'" xsi:type="CharTerm" MAX_LENGTH="500"  TERMINATOR="', seplast ,'" />' ) ,
            outputcols = str_c('<COLUMN SOURCE="', col_names, '" NAME="', col_names,'" xsi:type="SQLNVARCHAR"/>' )
    ) %>%
    summarise(inputcols = str_c(inputcols , collapse = "\n") ,
              outputcols= str_c(outputcols , collapse = "\n")  ) %>%
    mutate( xml = str_replace(xml_pattern , '#inputcols#' , inputcols)  %>%
              str_replace( '#outputcols#' , outputcols)  
    )%>%
    pull (xml)%>%
    write_file(str_c (output_folder , fmt_file))
  
  
  sql_openquery_pattern = " DROP TABLE IF EXISTS #temp_table# ;
                      select *
                      INTO  #temp_table#
                      FROM OPENROWSET(BULK '#datafile#', 
                				FORMATFILE = '#formatfile#' ,
                				FirstRow = #firstrow#  , 
                        CODEPAGE = #codepage#) AS s"
  
  
  sql_openquery =
    str_replace(sql_openquery_pattern , '#datafile#' ,data_file  ) %>%
    str_replace( '#formatfile#' ,str_c (output_folder , fmt_file)  )%>%
    str_replace( '#firstrow#' ,  as.character(first_row)  )%>%
    str_replace( '#codepage#' ,  as.character(code_page)  )  %>%
    str_replace_all( '#temp_table#' , output_table)    
  
  
  dbGetQuery(conn, sql_openquery) 
  
  
}

#main script

args=commandArgs(trailingOnly=TRUE)

#print (args [1])

tbparams = rlang::eval_tidy(parse_expr(str_c ("tibble(" ,args [1], ")")))

#print (tbparams$.rscript)

conn_input = dbConnect(odbc::odbc(), 
                 .connection_string = tbparams$.conn_input)

dest_file = str_c (tbparams$.output_folder , tbparams$.output_table , ".csv" )


#input
.tbinput =  dbGetQuery(conn_input, tbparams$.sql ) %>% 
              as_tibble() 


#.tboutput = rlang::eval_tidy(parse_expr  (tbparams$.rscript))

.tboutput = eval (parse (text = tbparams$.rscript) )

if ( tbparams$.output_table != 'NULL') {
  #output
  .tboutput %>% 
    write_delim (dest_file , append = F , delim = ";" ,col_names= T )
  
  
  #export output into table
  conn_output = dbConnect(odbc::odbc(), 
                          .connection_string =tbparams$.conn_output)
  
  
  export_table (conn_output , tbparams$.output_folder , tbparams$.output_table )
  
  file.remove(dest_file)
  
}

#write_file(tbparams$.rscript , 'D:\\Temp\\output.csv')