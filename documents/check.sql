-- COMP9311 15s1 Project 1 Check
--
-- MyMyUNSW Check

create or replace function
	proj1_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- proj1_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	proj1_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- proj1_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not proj1_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not proj1_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return proj1_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- proj1_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array[
				'q1', 'q2', 'q3', 'q4a', 'q4b', 'q4c', 'q5',
				'q6'
				];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Check functions for specific test-cases in Project 1
--

create or replace function check_q1() returns text
as $chk$
select proj1_check('view','q1','q1_expected',
                   $$select * from q1$$)
$chk$ language sql;

create or replace function check_q2() returns text
as $chk$
select proj1_check('view','q2','q2_expected',
                   $$select * from q2$$)
$chk$ language sql;

create or replace function check_q3() returns text
as $chk$
select proj1_check('view','q3','q3_expected',
                   $$select * from q3$$)
$chk$ language sql;

create or replace function check_q4a() returns text
as $chk$
select proj1_check('view','q4a','q4a_expected',
                   $$select * from q4a$$)
$chk$ language sql;

create or replace function check_q4b() returns text
as $chk$
select proj1_check('view','q4b','q4b_expected',
                   $$select * from q4b$$)
$chk$ language sql;

create or replace function check_q4c() returns text
as $chk$
select proj1_check('view','q4c','q4c_expected',
                   $$select * from q4c$$)
$chk$ language sql;

create or replace function check_q5() returns text
as $chk$
select proj1_check('view','q5','q5_expected',
                   $$select * from q5$$)
$chk$ language sql;

create or replace function check_q6() returns text
as $chk$
select proj1_check('function','q6','q6_expected',
                   $$select * from q6('COMP3311')$$)
$chk$ language sql;

--
-- Tables of expected results for test cases
--

drop table if exists q1_expected;
create table q1_expected (
    unswid integer,
    name longname
);

drop table if exists q2_expected;
create table q2_expected (
    nstudents bigint,
    nstaff bigint,
    nboth bigint
);

drop table if exists q3_expected;
create table q3_expected (
    name longname,
    ncourses bigint
);

drop table if exists q4a_expected;
create table q4a_expected (
    id integer
);

drop table if exists q4b_expected;
create table q4b_expected (
    id integer
);

drop table if exists q4c_expected;
create table q4c_expected (
    id integer
);

drop table if exists q5_expected;
create table q5_expected (
    name mediumstring
);

drop table if exists q6_expected;
create table q6_expected (
    course text,
    year integer,
    term text,
    convenor text
);




COPY q1_expected (unswid, name) FROM stdin;
3012907	Jordan Sayed
3101627	Yiu Man
3137719	Vu-Minh Samarasekera
3139456	Minna Henry-May
3158621	Sanam Sam
3163349	Kerry Plant
3193072	Ivan Tsitsiani
3195354	Marliana Sondhi
\.

COPY q2_expected (nstudents, nstaff, nboth) FROM stdin;
31361	24405	0
\.

COPY q3_expected (name, ncourses) FROM stdin;
Susan Hagon	248
\.

COPY q4a_expected (id) FROM stdin;
3040773
3172526
3144015
3124711
3131729
3173265
3159387
3124015
3126551
3183655
3128290
3192680
\.

COPY q4b_expected (id) FROM stdin;
3032185
3168474
3162463
3171891
3189546
3032240
3074135
3002883
3186595
3062680
3127217
3103918
3176369
3195695
3171566
3137680
3192533
3195008
3104466
3197893
3122796
3171666
3198807
3107927
3109365
3199922
3123330
3145518
3137777
\.

COPY q4c_expected (id) FROM stdin;
2127746
2106821
2101317
2274227
3058210
3002104
3040773
3064466
3039566
3170994
3160054
3066859
3058056
3040854
3032185
3028145
3168474
3162463
3171891
3172526
3044547
3189546
3095209
3032240
3074135
3144015
3071040
3002883
3124711
3186595
3150439
3037496
3038440
3075924
3062680
3003813
3055818
3034183
3113378
3131729
3173265
3127217
3103918
3176369
3118164
3195695
3165795
3159387
3171566
3137680
3192533
3195008
3199764
3119189
3156293
3124015
3126551
3044434
3104466
3197893
3182603
3171417
3183655
3105389
3177106
3152729
3143864
3166499
3107617
3192671
3122796
3171666
3109043
3198807
3125057
3107927
3128290
3109365
3192680
3199922
3159514
3152664
3129900
3123330
3145518
3137777
3179898
3112493
3138098
3162743
\.

COPY q5_expected (name) FROM stdin;
Faculty of Engineering
\.


COPY q6_expected (course, year, term, convenor) FROM stdin;
COMP3311	2003	S1	John Shepherd
COMP3311	2003	S2	Kwok Wong
COMP3311	2006	S1	Wei Wang
COMP3311	2006	S2	John Shepherd
COMP3311	2007	S1	John Shepherd
COMP3311	2007	S2	Wei Wang
COMP3311	2008	S1	John Shepherd
COMP3311	2009	S1	John Shepherd
COMP3311	2010	S1	Xuemin Lin
COMP3311	2011	S1	John Shepherd
COMP3311	2012	S1	John Shepherd
COMP3311	2013	S2	John Shepherd
\.




