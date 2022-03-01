Use master;
go 
create or alter procedure execute_rscript ( @sql varchar (1000) = NULL,
											@rscript  varchar (1000) ,
											@output_table  varchar (1000) =NULL ,
											@drop_output_table bit = 1 ,
											@script_output bit = 0) as 
begin

		declare @cmd varchar (8000) , 
				@rscriptexe varchar (100)= 'C:\"Program Files"\R\R-4.1.2\bin\Rscript.exe' ,
				@rscriptfile varchar (1000) =  'D:\Temp\execute_external_rscript.R' ,
				@output_folder varchar (1000)= 'D:\Temp\' ,
				@conn_input varchar (8000)  = 'driver={SQL Server};server=SERVERNAME;database=DATABASE ;trusted_connection=true' ,
				@conn_output varchar (8000)  = 'driver={SQL Server};server=SERVERNAME;database=DATABASE ;trusted_connection=true'
			
		declare @output_database varchar (500) 	,
				@args varchar (8000) ,
				@sql_output varchar (8000) 	 ;

		select @output_database =  a2.value
		from string_split (@conn_output , ';') a1
		cross apply string_split (a1.value , '=') a2
		where a1.value like 'database%'
				and a2.value !=  'database' ;

		set		@output_folder = REPLACE (@output_folder , '\' , '\\\\') ; 
		--- if output table is null take a unique name
		set @output_table =  CASE 
								WHEN @output_table IS NULL THEN 'NULL'
								WHEN @output_table = 'AUTO' THEN '[tmp_rscript_' + cast (newid () as varchar (50) ) +']'
							  ELSE @output_table
							  END ;
		
		set @args =  '".sql ='''+ ISNULL (@sql , 'select 1 as output') + 
					''',.conn_input = ''' + @conn_input + 
					''',.conn_output = ''' + @conn_output + 
					''',.output_table = ''' +@output_table + 
					''',.output_folder ='''+  @output_folder+ 
					''' , .rscript=''' +@rscript +'''"' ;

		set @cmd = @rscriptexe + ' ' + @rscriptfile + ' ' + REPLACE ( REPLACE (@args , CHAR(13)+CHAR(10) , ' ')  ,  CHAR(9) , ''  ) ;

		print LEN (@cmd) ;

		IF @script_output = 0
			exec xp_cmdshell @cmd , NO_OUTPUT;
		ELSE
			exec xp_cmdshell @cmd ;

		IF @output_table != 'NULL' 
		BEGIN

			set @sql_output = 'USE '+@output_database+';
								 SELECT * FROM ' + @output_table ;

			PRINT (@sql_output) ;
			exec (@sql_output) ;


			IF @drop_output_table =1 
			BEGIN
				set @sql_output = 'USE '+@output_database+';
							   DROP TABLE ' + @output_table ;
				exec (@sql_output) ;	
			END 

		END
end
