-=============== МОДУЛЬ 2. РАБОТА С БАЗАМИ ДАННЫХ =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите уникальные названия городов из таблицы городов.

select distinct city  from city c;




--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания, чтобы запрос выводил только те города,
--названия которых начинаются на “L” и заканчиваются на “a”, и названия не содержат пробелов.

select distinct city  from city c 
	where city like 'L%a'
    and city not like '% %';




--ЗАДАНИЕ №3
--Получите из таблицы платежей за прокат фильмов информацию по платежам, которые выполнялись 
--в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно, 
--и стоимость которых превышает 1.00.
--Платежи нужно отсортировать по дате платежа.

select payment_id, payment_date, amount
from payment p 
where payment_date::date between '2005-06-17' and '2005-06-19'
 and amount > 1.00
order by payment_date;


--ЗАДАНИЕ №4
-- Выведите информацию о 10-ти последних платежах за прокат фильмов.

select payment_id, payment_date, amount  
from payment p
order by payment_date desc 
limit 10;



--ЗАДАНИЕ №5
--Выведите следующую информацию по покупателям:
--  1. Фамилия и имя (в одной колонке через пробел)
--  2. Электронная почта
--  3. Длину значения поля email
--  4. Дату последнего обновления записи о покупателе (без времени)
--Каждой колонке задайте наименование на русском языке.

select concat(last_name, ' ', first_name) as "Фамилия и имя", email as "Электронная почта", 
length(email) as "Длина Email", last_update::date as "Дата"
from customer;


--ЗАДАНИЕ №6
--Выведите одним запросом только активных покупателей, имена которых KELLY или WILLIE.
--Все буквы в фамилии и имени из верхнего регистра должны быть переведены в нижний регистр.

select lower(last_name) as last_name, lower(first_name) as first_name, active 
from customer c
where (first_name = 'KELLY' or first_name = 'WILLIE') and active = 1;



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите одним запросом информацию о фильмах, у которых рейтинг "R" 
--и стоимость аренды указана от 0.00 до 3.00 включительно, 
--а также фильмы c рейтингом "PG-13" и стоимостью аренды больше или равной 4.00.

select film_id, title, description, rating, rental_rate
from film
where rating = 'R' and rental_rate between 0.00 and 3.00
	or rating = 'PG-13' and rental_rate >= 4.00;



--ЗАДАНИЕ №2
--Получите информацию о трёх фильмах с самым длинным описанием фильма.

select film_id, title, description, char_length(description) 
from film
order by 4  desc 
fetch first 3 rows with ties;
 
select film_id, title, char_length(description) 
from film f
limit 3;

--ЗАДАНИЕ №3
-- Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:
--в первой колонке должно быть значение, указанное до @, 
--во второй колонке должно быть значение, указанное после @.

select customer_id, email, 
split_part(email, '@', 1) AS "Email before @",
split_part(email, '@', 2) AS "Email after @"
from customer c;



--ЗАДАНИЕ №4
--Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках: 
--первая буква должна быть заглавной, остальные строчными.

select customer_id, email, 
concat(upper(left(split_part(email, '@', 1), 1)), lower(right(split_part(email, '@', 1), -1))) AS "Email before @", 
concat(upper(left(split_part(email, '@', 2), 1)), lower(right(split_part(email, '@', 2), -1))) AS "Email after @"
from customer;

select customer_id, email, 
concat(upper(left(email, 1)), lower(right(split_part(email, '@', 1), -1))) AS "Email before @", 
concat(upper(left(split_part(email, '@', 2), 1)), lower(right(split_part(email, '@', 2), -1))) AS "Email after @"
from customer;



