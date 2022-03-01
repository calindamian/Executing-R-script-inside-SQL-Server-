# Executing-R-script-inside-SQL-Server-
Alternative of SQL Server sp_execute_external_script to allow mixing of SQL and R language 

## Objective

Have you allready got frustrated of Microsoft sp_execute_external_script (aka Machine Learning Services) and limited support of allowing 
setting any version of R language ?

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
  5. Copy **execute_external_rscript.R** in configured @rscriptfile path.


## Usage
                        
The __execute_rscript__  stored procedure has the following params:

      @sql:                      input sql query representing input dataset.
      
      @rscript:                  R script to be executed in the current context.
                                    eg:  library (lubridate) ;
                                          .tbinput %>% 
                                           mutate (CurrentDate = today ()) 
                                    The input dataset is accessible from R script via **.tbinput** variable.
                                    The output of the R script should be in the tibble form so we can output a table back to SQL.
                                    
      @output_table:              Output table name to store the output dataset return from the script.
                                          - the table name used to store the output dataset
                                          - If NULL the script will be executed but the output wont be stored as table
                                          - If'AUTO' the table name is uniquely generated and the table name is retured in @output_table variable
                                          
      @drop_output_table:         Controls the persistance of the output table (default 1)
                                           - If  @drop_output_table = 1 output table is droped.
                                           - If  @drop_output_table = 0 output table is kept.
                                           
      @script_output              Controls additional script shell output (default 0) 
                                           - If  @script_output = 1 shows additional shell output.
                                           - If  @script_output = 0 suppress shell output.          
## Exemples
```
---- input data and append an R calculated column
exec master..execute_rscript @sql = 'select  cast ([ClosedDate] as date ) as  [ClosedDate] , 
									count (*) as Cnt ,
									max (Score) as Score ,
									sum (cast (ViewCount as bigint ) ) as ViewCount 
									from [StackOverflow2010].[dbo].[Posts]
									group by cast ([ClosedDate] as date )',

								@rscript  = 'library (lubridate) ;
											.tbinput %>% 
											 mutate (CurrentDate = today ()) ' ,
								@output_table  = 'tmp_out'



---in order to type the results use WITH RESULT SETS
exec master..execute_rscript @sql = 'select  cast ([ClosedDate] as date ) as  [ClosedDate] , 
									count (*) as Cnt ,
									max (Score) as Score ,
									sum (cast (ViewCount as bigint ) ) as ViewCount 
									from [StackOverflow2010].[dbo].[Posts]
									group by cast ([ClosedDate] as date )',

								@rscript  = '.tbinput %>% 
											  summarise(correlation = cor(ViewCount , Score)) ' ,
								@output_table  = 'tmp_out'

WITH RESULT SETS (  (correlation float  ));  

--- execute as script with no table output and activate script output
exec master..execute_rscript	@rscript  = 'print (sessionInfo () )' ,
								@script_output = 1
```

## Conclusions

Wait for your comments and suggestions and if you find it useful the crypto donations are more than welcomed ...

BTC wallet : bc1qm06aatgwn8ducjtexu6cf0wle0d9r00fy7yp7y

or via paystring : calin.damian.crypto$paystring.crypto.com

