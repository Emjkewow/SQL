--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

select film_id, title, special_features 
from film f 
where special_features::text  like '%Behind the Scenes%'

explain analyze -- 113.75/0.91
select film_id, title, special_features
from film f
where 'Behind the Scenes' in (select unnest(special_features))

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

explain analyze -- 67.50/0.42
select film_id, title, special_features
from film f
where special_features && array['Behind the Scenes']

explain analyze -- 67.50/0.48
select film_id, title, special_features
from film f
where special_features @> array['Behind the Scenes']

explain analyze -- 77.50/0.36
select film_id, title, special_features
from film f
where 'Behind the Scenes' = any(special_features)

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

with cte as (
	select film_id, title, special_features
	from film f
	where special_features @> array['Behind the Scenes'])
select c.customer_id, count(*) as film_count
from customer c 
join rental r on r.customer_id = c.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join cte on cte.film_id = i.film_id 
group by c.customer_id 
order by c.customer_id 



--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

select r.customer_id, count(*) as film_count
from (
	select film_id, title, special_features
	from film f
	where special_features @> array['Behind the Scenes']) t
join inventory i on i.film_id = t.film_id  
join rental r on r.inventory_id = i.inventory_id 
group by r.customer_id 
order by r.customer_id 

--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view task_5 as
	select r.customer_id, count(*) as film_count
	from (
		select film_id, title, special_features
		from film f
		where special_features @> array['Behind the Scenes']) t
	join inventory i on i.film_id = t.film_id  
	join rental r on r.inventory_id = i.inventory_id 
	group by r.customer_id 
	order by r.customer_id

refresh materialized view task_5

select * from task_5

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее
--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

explain analyze -- 720.76/14.75
with cte as (
	select film_id, title, special_features
	from film f
	where special_features @> array['Behind the Scenes'])
select c.customer_id, count(*) as film_count
from customer c 
join rental r on r.customer_id = c.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join cte on cte.film_id = i.film_id 
group by c.customer_id 
order by c.customer_id 

explain analyze -- 675.48/10.5
select r.customer_id, count(*) as film_count
	from (
		select film_id, title, special_features
		from film f
		where special_features @> array['Behind the Scenes']) t
	join inventory i on i.film_id = t.film_id  
	join rental r on r.inventory_id = i.inventory_id 
	group by r.customer_id 
	order by r.customer_id

	-- 1. поиск значения в массиве происходит быстрее с помощью оператора any, но он немного дороже
	-- 2. вариант вычислений с использованием подзапроса работает быстрее чем CTE
	

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.





--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день




