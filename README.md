# Executing-R-script-inside-SQL-Server-
Alternative of SQL Server sp_execute_external_script to allow mixing of SQL and R language 

## Objective

Have you allready got frustrated of Microsoft sp_execute_external_script (aka Machine Learning Services) and limited support of allowing setting any version of R language ?

If the answer is yes this post is for you...

Usually you have to wait for a new version of SQL Server that hopefully supports the latest version of R.

I 've created a stored procedure ( based on the old xp_cmdshell ) that allows running R scripts in whatever version you like. 

First I explained  how to install it and then how you can use it.

## Installation

1. Download and install an R language runtime version on your SQL Server machine:  https://cran.r-project.org/bin/windows/

2. Once you've installed R make sure you install the following packages: 
      - install.packages("tidyverse")
      - install.packages("DBI")

3. Open an SQL Client and open install_execute_rscript.sql.
   
   Modify the following variables to match your environement
    - @rscriptexe :     path to Rscript.exe (eg: 'C:\"Program Files"\R\R-4.1.2\bin\Rscript.exe' )
                        The login used for SQL Server should be allowed execution. 
    - @rscriptfile:     path to main script that wraps R SQL execution  (eg: 'D:\Temp\execute_external_rscript.R' )
    - @output_folder:   name of temporary folder used to dump temp files used by the script. (eg:  'D:\Temp\').
                        The login used for SQL should have access to this folder.
    - @conn_input:      connection string to be used for the input query. 
                        (eg: 'driver={SQL Server};server=SQLSERVER;database=StackOverflow2010;trusted_connection=true') 
                        Make sure the login used for SQL Server has access to the configured SQL Server 
    - @conn_output:     connection string to be used for storing the table containing output results. 
                        (eg: 'driver={SQL Server};server=SQLSERVER;database=TMP;trusted_connection=true') 
                        Make sure the login used for SQL Server has access to the configured SQL Server 
                        
  4. Execute **install_execute_rscript.sql**.                    

## Usage

