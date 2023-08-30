--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select concat(c.last_name, ' ', c.first_name ), a.address , c2.city  , c3.country 
from customer c 
join address a on a.address_id = c.address_id 
join city c2 on c2.city_id = a.city_id 
join country c3 on c2.country_id  = c3.country_id 




--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select store_id , count(customer_id) 
from customer c 
group by store_id



--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select store_id, count(customer_id)
from customer c 
group by store_id
having count(customer_id) > 300




-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select s.store_id, count(c.customer_id), c2.city , concat(s2.first_name, ' ', s2.last_name)
from store s 
join customer c on c.store_id = s.store_id 
join address a on a.address_id = s.address_id 
join city c2 on c2.city_id = a.city_id 
join staff s2 on s2.store_id = s.store_id 
group by s.store_id, c2.city, s2.first_name , s2.last_name
having count(customer_id) > 300



--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select concat(first_name, ' ', last_name), count(r.rental_id) 
from customer c 
join rental r on c.customer_id = r.customer_id 
group by c.customer_id 
order by count(r.rental_id) desc 
limit 5



--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select concat(c.first_name, ' ', c.last_name), count(i.film_id), round(sum(p.amount)), min(p.amount), max(p.amount) 
from customer c 
join rental r on c.customer_id = r.customer_id 
join payment p on p.rental_id  = r.rental_id 
join inventory i on i.inventory_id = r.inventory_id 
group by c.customer_id 



--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 
select c1.city , c2.city 
from city c1, city c2
where c1.city != c2.city



--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 
select customer_id , round(avg(date_part('day', return_date - rental_date::date))::numeric , 2) 
from rental 
group by customer_id 
order by customer_id asc



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

 
select f.title , f.rating , c."name" , f.release_year , l."name" , count(p.payment_id), sum(p.amount) 
from rental r
join payment p on r.customer_id = p.customer_id 
join inventory i on r.inventory_id = i.inventory_id 
join film f on i.film_id = f.film_id 
join "language" l on f.language_id = l.language_id 
join film_category fc on fc.film_id = f.film_id
join category c on c.category_id = fc.category_id 
group by r.rental_id, f.title, f.rating, f.release_year, l."name" , c."name"       



--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.

select f.title , f.rating , c."name" , f.release_year , l."name" , count(p.payment_id), sum(p.amount) 
from rental r
right join payment p on r.customer_id = p.customer_id 
right join inventory i on r.inventory_id = i.inventory_id 
right join film f on i.film_id = f.film_id 
join "language" l on f.language_id = l.language_id 
join film_category fc on fc.film_id = f.film_id
join category c on c.category_id = fc.category_id 
group by r.rental_id, f.title, f.rating, f.release_year, l."name" , c."name" 
having count(p.payment_id) = 0

-- БОЛЕЕ ТОЧНЫЙ
select f.title, f.rating, c."name", f.release_year, l."name", count(r.rental_id), sum(p.amount)
from film f
left join film_category fc on f.film_id = fc.film_id
left join category c on c.category_id = fc.category_id
left join "language" l on l.language_id = f.language_id
left join inventory i on i.film_id = f.film_id
left join rental r on r.inventory_id = i.inventory_id
left join payment p on r.rental_id = p.rental_id
where i.film_id is null
group by f.film_id, c.category_id, l.language_id

-- ЧЕРЕЗ ПОДЗАПРОС

select t.title, t.rating, c."name", t.release_year, l."name", count, sum
from (
	select f.film_id, f.title, f.language_id, f.rating, f.release_year, count(r.rental_id), sum(p.amount)
	from film f
	left join inventory i on i.film_id = f.film_id
	left join rental r on r.inventory_id = i.inventory_id
	left join payment p on r.rental_id = p.rental_id
	where i.film_id is null
	group by f.film_id) t
left join film_category fc on t.film_id = fc.film_id
left join category c on c.category_id = fc.category_id
left join "language" l on l.language_id = t.language_id

--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select s.staff_id, concat(s.first_name, ' ', s.last_name), count(*),
	case 
		when count(*) > 7300 then 'da'
		else 'no'
	end
from staff s
left join payment p on s.staff_id = p.staff_id
group by 1





