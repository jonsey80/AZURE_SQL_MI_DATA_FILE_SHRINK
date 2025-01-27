
drop table if exists #space_used
create table #space_used (

dbname varchar(100)  ,
fileid int null ,
typedesc varchar(40) ,
[space_used (MB)] numeric(19,2) null

)
 exec sp_MSforeachdb '		use [?]
		insert into #space_used
		SELECT ''?'', file_id, type_desc,
       CAST(FILEPROPERTY(name, ''SpaceUsed'') AS decimal(19,4)) * 8 / 1024. AS space_used_mb

FROM sys.database_files'



drop table if exists #iops_Bucket
Create table #IOPS_Bucket (
[Bucket]	varchar(100)	null,
[Min_fileSize] [bigint] null,
[max_fileSize] [bigint] null,
[IOPS]	[bigint] null,
[Throughput(MiB/s)] [int] null
)

insert into #iops_bucket
values 
('>=0 and <=129 GiB', 0, 129, 500, 100),
('>129 and <=513 GiB', 130,513,2300,150),
('>513 and <=1025 GiB', 514,1025,5000,200),
('>1025 and <=2049 GiB',1026,2049,7500,250),
('>2049 and <=4097 GiB',2050,4097,7500,250),
('>4097 GiB and <=8 TiB',4098,80000000000,7500,250)

Select [DatabaseName],
	   [FileName],
	   [File_type],
	   [Current_file_size (MB)],
	   [space_used (MB)],
	   [Current_file_size (MB)] - [space_used (MB)] 'Free_space (MB)',
	   [bucket] 'Current_IOPS_bucket',
	   max_filesize ,
	   Case When [Current_file_size (MB)]/1024 < 129 then [Current_file_size (MB)] - [space_used (MB)]
			when ([Current_file_size (MB)] - ([Current_file_size (MB)] - [space_used (MB)]))/1024 > min_filesize then  [Current_file_size (MB)] - [space_used (MB)]
			else ([Current_file_size (MB)]/1024 - min_filesize) * 1024 
			end 'Space_shrinkable(MB)'
From (	select dbl.name 'DatabaseName',
			   masf.name 'FileName',
			   masf.file_id,
			   masf.type_desc 'File_type',
			   ((convert(Numeric(19,2),masf.size)*8)/1024) 'Current_file_size (MB)'	   
		from sys.databases dbl
		inner join sys.master_files masf on dbl.database_id = masf.database_id
		where dbl.database_id > 4 ) t
inner join #IOPS_Bucket on [Current_file_size (MB)]/1024 > [Min_fileSize] and [Current_file_size (MB)]/1024 < [Max_fileSize]
inner join #space_used spu on t.[DatabaseName] = spu.dbname and  t.[file_id] = spu.[fileid] 
where File_type = 'Rows'

