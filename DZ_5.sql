--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим 
--так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select customer_id, payment_id, payment_date,
	row_number () over(order by payment_date, amount),
	row_number() over (partition by customer_id order by payment_date),
    sum(p.amount) over (partition by p.customer_id order by p.payment_date, amount),
    dense_rank() over (partition by p.customer_id order by amount desc)
from payment p 
order by customer_id, dense_rank



--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.

select customer_id, payment_id, payment_date, amount, 
	lag(p.amount, 1, 0.) over(partition by customer_id order by p.payment_date)
from payment p 
order by customer_id 



--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select customer_id, payment_id, payment_date, amount,
	amount - lead(p.amount, 1, 0.) over (partition by customer_id  order by p.payment_date, customer_id)
from payment p 
order by customer_id 



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

explain analyse ---1786
select customer_id, payment_id, payment_date, amount
from (
	select *, first_value(payment_id) over (partition by customer_id order by payment_date desc)
	from payment p) t
where payment_id = first_value

--- Без оконных функций

explain analyse ---744
select p.customer_id, p.payment_id, p.payment_date, p.amount
from payment p
inner join (
  select customer_id, max(payment_date) as max_payment_date
  from payment
  group by customer_id
) as t
on p.customer_id = t.customer_id and p.payment_date = t.max_payment_date



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

select staff_id, date_trunc('day', payment_date) as payment_date,
	sum(amount),
	sum(sum(amount)) over (partition by staff_id order by date_trunc('day', payment_date) rows between unbounded preceding and current row)
from payment
where date_trunc('month', payment_date) = '2005-08-01'
group by staff_id, date_trunc('day', payment_date)  
order by date_trunc('day', payment_date)

select staff_id, payment_date::date, sum(amount), 
	sum(sum(amount)) over (partition by staff_id order by payment_date::date)
from payment 
where date_trunc('month', payment_date) = '01.08.2005'
group by staff_id, payment_date::date

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

explain analyze --123.42 / 0.55
select *
from (
	select *, row_number() over (order by payment_date)
	from payment 
	where payment_date::date = '20.08.2005') t
--where row_number % 100 = 0
--where row_number::text like '%00'
where mod(row_number, 100) = 0

explain analyze --1365.97 / 3.1
with recursive r as (
	select *
	from (select payment_date, customer_id, row_number () over (order by payment_date)
	from payment
	where payment_date::date = '2005-08-20') t1
	where row_number = 100
	union 
	select t2.payment_date, t2.customer_id, r.row_number + 100 as row_number
	from r
	join (
		select payment_date, customer_id, row_number () over (order by payment_date)
		from payment
		where payment_date::date = '2005-08-20') t2 on t2.row_number - 100 = r.row_number)
select *
from r




--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

explain analyze --8161.25 / 30
with cte1 as (
	select c.customer_id, c2.country_id, count(i.film_id), sum(p.amount), max(r.rental_date), concat(c.last_name, ' ', c.first_name)
	from rental r
	join inventory i on r.inventory_id = i.inventory_id
	join payment p on r.rental_id = p.rental_id
	join customer c on c.customer_id = r.customer_id
	join address a on a.address_id = c.address_id
	join city c2 on c2.city_id = a.city_id
	group by c.customer_id, c2.country_id), 
cte2 as (
	select country_id, concat, 
		row_number() over (partition by country_id order by count desc) rc,
		row_number() over (partition by country_id order by sum desc) rs,
		row_number() over (partition by country_id order by max desc) rm
	from cte1)
select c.country, c1.concat, c2.concat, c3.concat
from country c
left join cte2 c1 on c1.country_id = c.country_id and c1.rc = 1
left join cte2 c2 on c2.country_id = c.country_id and c2.rs = 1
left join cte2 c3 on c3.country_id = c.country_id and c3.rm = 1

explain analyze --1258.88 / 12
with cte1 as (
	select r.customer_id, count, sum, max
	from (
		select customer_id, count(i.film_id), max(r.rental_date)
		from rental r
		join inventory i on r.inventory_id = i.inventory_id
		group by r.customer_id) r
	join (
		select customer_id, sum(amount)
		from payment 
		group by customer_id) p on r.customer_id = p.customer_id),
cte2 as (
	select c2.country_id, concat(c.last_name, ' ', c.first_name), 
		ct.count, ct.sum, ct.max,
		case when ct.count = max(ct.count) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cc,
		case when ct.sum = max(ct.sum) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cs,
		case when ct.max = max(ct.max) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cm
	from cte1 ct
	join customer c on c.customer_id = ct.customer_id
	join address a on a.address_id = c.address_id
	join city c2 on c2.city_id = a.city_id)
select c.country, string_agg(cc, ', '), string_agg(cs, ', '), string_agg(cm, ', ')
from country c
left join cte2 c2 on c.country_id = c2.country_id
group by c.country_id




