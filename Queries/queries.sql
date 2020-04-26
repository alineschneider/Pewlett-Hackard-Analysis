-- Retirement eligibility
SELECT first_name, last_name
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

SELECT first_name, last_name
FROM employees
WHERE birth_date BETWEEN '1952-01-01' AND '1952-12-31';

SELECT first_name, last_name
FROM employees
WHERE birth_date BETWEEN '1953-01-01' AND '1953-12-31';

-- Number of employees retiring
SELECT COUNT(first_name)
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

SELECT first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

DROP TABLE retirement_info;

-- Create new table for retiring employees
SELECT emp_no, first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');
-- Check the table
SELECT * FROM retirement_info;

-- Joining departments and dept_manager tables (inner join, with alias)
SELECT d.dept_name,
       dm.emp_no,
       dm.from_date,
       dm.to_date
FROM departments as d
INNER JOIN dept_manager as dm
ON d.dept_no = dm.dept_no;

-- Joining retirement_info and dept_emp tables (inner join)
SELECT retirement_info.emp_no,
	   retirement_info.first_name,
	   retirement_info.last_name,
	   dept_emp.to_date
FROM retirement_info
LEFT JOIN dept_emp
ON retirement_info.emp_no = dept_emp.emp_no;

-- Joining retirement_info and dept_emp tables (inner join, with alias)
SELECT ri.emp_no,
	   ri.first_name,
	   ri.last_name,
	   de.to_date
FROM retirement_info as ri
LEFT JOIN dept_emp as de
ON ri.emp_no = de.emp_no;

-- Make sure that they are actually still employed with PH:
SELECT ri.emp_no,
	ri.first_name,
	ri.last_name,
	de.to_date
INTO current_emp
FROM retirement_info as ri
LEFT JOIN dept_emp as de
ON ri.emp_no = de.emp_no
WHERE de.to_date = ('9999-01-01');

-- Employee count by department number
SELECT COUNT(ce.emp_no), de.dept_no
INTO emp_dept
FROM current_emp as ce
LEFT JOIN dept_emp as de
ON ce.emp_no = de.emp_no
GROUP BY de.dept_no
ORDER BY de.dept_no;

-- Cleaning Employees, filtered by age and hire date
SELECT e.emp_no,
	e.first_name,
	e.last_name,
	e.gender,
	s.salary,
	de.to_date
INTO emp_info
FROM employees as e
INNER JOIN salaries as s
ON (e.emp_no = s.emp_no)
INNER JOIN dept_emp as de
ON (e.emp_no = de.emp_no)
WHERE (e.birth_date BETWEEN '1952-01-01' AND '1955-12-31')
     AND (e.hire_date BETWEEN '1985-01-01' AND '1988-12-31')
	 AND (de.to_date = '9999-01-01');

-- List of managers per department
SELECT  dm.dept_no,
        d.dept_name,
        dm.emp_no,
        ce.last_name,
        ce.first_name,
        dm.from_date,
        dm.to_date
INTO manager_info
FROM dept_manager AS dm
    INNER JOIN departments AS d
        ON (dm.dept_no = d.dept_no)
    INNER JOIN current_emp AS ce
        ON (dm.emp_no = ce.emp_no);

-- List of department retirees
SELECT ce.emp_no,
	ce.first_name,
	ce.last_name,
	d.dept_name
INTO dept_info
FROM current_emp as ce
INNER JOIN dept_emp AS de
ON (ce.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no);

SELECT * FROM dept_info

-- List of retirees from Sales department
SELECT ri.emp_no, 
	ri.first_name, 
	ri.last_name,
	d.dept_name
-- INTO retirement_info_sales
FROM retirement_info AS ri
INNER JOIN dept_emp AS de
ON (ri.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no)
WHERE (d.dept_name = 'Sales');

-- List of retirees from both Sales and Development departments
SELECT ri.emp_no, 
	ri.first_name, 
	ri.last_name,
	d.dept_name
-- INTO retirement_info_sales
FROM retirement_info AS ri
INNER JOIN dept_emp AS de
ON (ri.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no)
WHERE d.dept_name IN ('Sales', 'Development')

-- Challenge
-- Technical Analysis Deliverable 1
-- Retiring Employees (duplicates removed without partitioning)
SELECT  ce.emp_no,
        ce.first_name,
        ce.last_name,
		t.title,
        t.from_date,
		s.salary
INTO deliverable_1_retirees_info
FROM current_emp AS ce
    INNER JOIN title AS t
        ON (ce.emp_no = t.emp_no)
    INNER JOIN salaries AS s
        ON (ce.emp_no = s.emp_no)
WHERE t.to_date = ('9999-01-01');

-- Retiring Employees (Partitioning to remove duplicates):
SELECT emp_no,
	first_name,
	last_name,
	title,
	from_date,
	salary
INTO deliverable_1_retirees_info
FROM
	(SELECT emp_no,
	first_name,
	last_name,
	title,
	from_date,
	salary,
	ROW_NUMBER() OVER
	(PARTITION BY (emp_no)
	ORDER BY from_date DESC) rn
	FROM
		(SELECT ce.emp_no,
        ce.first_name,
        ce.last_name,
		t.title,
        t.from_date,
		s.salary
		FROM current_emp AS ce
    	INNER JOIN title AS t
        ON (ce.emp_no = t.emp_no)
    	INNER JOIN salaries AS s
        ON (ce.emp_no = s.emp_no)) AS rd)
	tpm WHERE rn = 1
ORDER BY emp_no;

-- Number of retiring employees grouped by title
SELECT t.title, COUNT(ce.emp_no)
INTO deliverable_1_retirees_by_title
FROM current_emp AS ce
INNER JOIN title AS t
ON (ce.emp_no = t.emp_no)
WHERE t.to_date = ('9999-01-01')
GROUP BY t.title;

-- Technical Analysis Deliverable 2
-- Mentorship Eligibility
SELECT e.emp_no,
	   e.first_name,
	   e.last_name,
	   t.title,
	   t.from_date,
	   t.to_date
INTO deliverable_2_mentorship_eligibility
FROM employees AS e
INNER JOIN title AS t
ON (e.emp_no = t.emp_no)
WHERE (e.birth_date BETWEEN '1965-01-01' AND '1965-12-31')
	AND (t.to_date = ('9999-01-01'));



