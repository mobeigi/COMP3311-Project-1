-- COMP9311 15s1 Project 1
--
-- MyMyUNSW Solution
-- By: Mohammad Ghasembeigi (z3464208)

-- Q1: Gives the student id and name of any student who has studied more than 65 courses at UNSW. The name should be taken from the People.name field for the student, and the student id should be taken from People.unswid.

create or replace view Q1(unswid, name)
as
  SELECT p.unswid AS unswid, p.name AS name
  FROM people p JOIN course_enrolments c ON (p.id = c.student)
  GROUP BY p.unswid, p.name
    HAVING count(*) > 65
;

/*
-- Q2: Produces a table with a single row containing counts of:

- the total number of students (who are not also staff)
- the total number of staff (who are not also students)
- the total number of people who are both staff and student.
*/

-- Helper view to get total number of students (who are not also staff)
create or replace view __Q2NSTUDENTS(nstudent)
as
  SELECT COUNT(*) AS nstudent FROM 
  (
    SELECT p.id FROM students s JOIN people p ON (s.id = p.id)
      EXCEPT
    SELECT p.id FROM staff s JOIN people p ON (s.id = p.id)
  ) AS __Q2COUNTSUB
;

-- Helper view to get total number of staff (who are not also students)
create or replace view __Q2NSTAFF(nstaff)
as
  SELECT COUNT(*) AS nstaff FROM 
  (
    SELECT p.id FROM staff s JOIN people p ON (s.id = p.id)
      EXCEPT
    SELECT p.id FROM students s JOIN people p ON (s.id = p.id)
  ) AS __Q2COUNTSUB
;

-- Helper view to get total number of people who are both staff and student
create or replace view __Q2NBOTH(nboth)
as
  SELECT COUNT(*) AS nboth FROM 
  (
    SELECT p.id FROM students s JOIN people p ON (s.id = p.id)
      INTERSECT 
    SELECT p.id FROM staff s JOIN people p ON (s.id = p.id)
  ) AS __Q2COUNTSUB
;

-- Q2 (view which utilises 3 helper views)
create or replace view Q2(nstudents, nstaff, nboth)
as
  SELECT * FROM __Q2NSTUDENTS, __Q2NSTAFF, __Q2NBOTH
;

-- Q3: Define an SQL view Q3(name, ncourses) that prints the name of the person(s) who has been lecturer-in-charge (LIC) of the most courses at UNSW and the number of courses they have been LIC for. In the database, the LIC has the role of "Course Convenor".

-- Helper view to get Course Convenor ID
create or replace view __Q3GETLICID(id)
as
  SELECT id FROM staff_roles WHERE name = 'Course Convenor'
;

-- Helper view to get staff list and corresponding course count
create or replace view __Q3GetStaffCourseCount(staff, courseCount)
as
  SELECT staff as staff, count(*) as courseCount FROM course_staff 
  WHERE role = (SELECT * FROM __Q3GETLICID)
  GROUP BY staff
;

-- Q3
create or replace view Q3(name, ncourses)
as

  SELECT p.name AS name, STT.courseCount AS ncourses
  FROM (SELECT * FROM __Q3GetStaffCourseCount) STT
  JOIN people p ON (p.id = STT.staff)
  WHERE STT.courseCount = 
  (
    SELECT MAX(courseCount)
    FROM (SELECT * FROM __Q3GetStaffCourseCount) AS MAXSTT
  )
;

-- Q4: ...

-- Helper view to get ID for semester 2 of 2005
create or replace view __Q4GET05S2ID(id)
as
  SELECT id FROM semesters WHERE name = 'Sem2 2005'
;

-- Gives student IDS of all students enrolled in 05s2 in the Computer Science (3978) degree
create or replace view Q4a(id)
as
  SELECT p.unswid AS id
  FROM program_enrolments pe JOIN people p ON (pe.student = p.id)
  WHERE pe.semester = (SELECT * FROM __Q4GET05S2ID)
  AND pe.program IN (SELECT id FROM programs WHERE code = '3978')
;

-- Gives student IDS of all students enrolled in 05s2 in the Software Engineering (SENGA1) stream
create or replace view Q4b(id)
as
  
  SELECT p.unswid AS id
  FROM program_enrolments pe JOIN people p ON (pe.student = p.id)
  WHERE pe.semester = (SELECT * FROM __Q4GET05S2ID)
  AND pe.id IN (
                 SELECT partof 
                 FROM stream_enrolments
                 WHERE stream IN (SELECT id FROM streams WHERE code = 'SENGA1')
                )
  ORDER BY p.id
;

-- Gives student IDS of all students enrolled in 05s2 in degrees offered by CSE
create or replace view Q4c(id)
as
                
  SELECT p.unswid AS id
  FROM program_enrolments pe JOIN people p ON (pe.student = p.id) 
  WHERE pe.program IN (
                    SELECT id FROM programs where
                    offeredby = (
                                  SELECT id 
                                  FROM orgunits 
                                  WHERE name LIKE '%Computer Science and Engineering%'
                                 )
                    )
  AND semester = (SELECT * FROM __Q4GET05S2ID)
;

-- Q5: Gives the faculty with the maximum number of committees.

-- Helper View to get committ
create or replace view __Q5CommitteeList(committeeCount, faculty)
as
  SELECT COUNT(id) as committeeCount, facultyof(id) as faculty
  FROM ( 
      SELECT ou.id AS id
      FROM orgunits ou 
      JOIN (
            SELECT id 
            FROM orgunit_types 
            WHERE name = 'Committee'
           ) ou_type
          ON (ou.utype = ou_type.id)
      ) AS com
  WHERE facultyof(id) != id
  GROUP BY facultyof(id)
;
-- Q5
create or replace view Q5(name)
as

 SELECT ou.name AS name
 FROM (SELECT * FROM __Q5CommitteeList) maxRes JOIN orgunits ou ON (maxRes.faculty = ou.id)
 WHERE committeeCount = (
                          SELECT MAX(committeeCount) 
                          FROM (SELECT * FROM __Q5CommitteeList) AS maxRes
                        )
;

-- Q6: Takes as parameter a UNSW course code (e.g. COMP1917) and returns a list of all offerings of the course for which a Course Convenor is known.

create or replace function Q6(text)
	returns table (course text, year integer, term text, convenor text)
as $$

  SELECT $1, sem.year, CAST(sem.term as text), p.name
  FROM subjects subj
  JOIN courses c ON (c.subject=subj.id)
  JOIN semesters sem ON (sem.id=c.semester)
  JOIN course_staff cs ON (cs.course=c.id)
  JOIN staff_roles sr ON (sr.id=cs.role)
  JOIN people p ON (cs.staff=p.id)

  WHERE subj.code = $1
  AND sr.name = 'Course Convenor'

$$ language sql
;