------------------Проектная работа по модулю
-------------------“SQL и получение данных”

-- 1. Выведите название самолетов, которые имеют менее 50 посадочных мест?

 select a.aircraft_code, a.model, count(seat_no) as seats
 from aircrafts a 
 join seats s on s.aircraft_code = a.aircraft_code 
group by a.aircraft_code 
having  count(seat_no) < 50
 
 
 -- 2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.


with cte as (
	select date_trunc('month', book_date) as month, sum(total_amount) as total
	from bookings b 
	group by month)
select cte.*,
	round(((total / lag(total) over (order by month) - 1)* 100), 2) as total_change
from cte
order by month 



-- 3. Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.



select a.model, array_agg(s.fare_conditions)
from aircrafts a
join seats s on s.aircraft_code = a.aircraft_code
group by a.model
having not array_agg(s.fare_conditions::text) @> ARRAY['Business'];


-- 4. Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день, учитывая только те самолеты, которые летали пустыми и только те дни,
------где из одного аэропорта таких самолетов вылетало более одного.
------В результате должны быть код аэропорта, дата, количество пустых мест и накопительный итог.
  

with cte1 as  ( 
    select f.flight_id, f.departure_airport, f.actual_departure, count(*) as empty_seats, count(*) over (partition by departure_airport, actual_departure::date) as empty_flights_count
    from flights f
        join airports a on f.arrival_airport  = a.airport_code
        join airports a1 on f.departure_airport = a1.airport_code 
        join seats s on f.aircraft_code = s.aircraft_code 
    where
        not exists (
            select 1
            from boarding_passes bp
            where bp.flight_id = f.flight_id 
        ) and f.actual_departure is not null 
    group by f.flight_id, f.departure_airport, f.actual_departure
  )
 select departure_airport, actual_departure::date, empty_seats, 
        sum(empty_seats) over (partition by departure_airport, actual_departure::date order by actual_departure) as cumulative_seats
   from cte1
  where empty_flights_count > 1
 




-- 5. Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов. 
------Выведите в результат названия аэропортов и процентное отношение.
------Решение должно быть через оконную функцию.

with route_counts as (
    select 
        f.flight_no,
        a1.airport_name as airport_dep, f.departure_airport,
        a2.airport_name as airport_arive, f.arrival_airport,
        count(f.flight_id) as flights_count
    from flights f
    join airports a1 on f.departure_airport = a1.airport_code 
    join airports a2 on f.arrival_airport = a2.airport_code
    group by f.flight_no, f.departure_airport, f.arrival_airport, a1.airport_code, a2.airport_code, a1.airport_name, a2.airport_name 
)
select
    airport_dep, --departure_airport,
    airport_arive, --arrival_airport,
    flights_count,
    round((flights_count * 100.0 / sum(flights_count) over ()), 3) as percentage
from route_counts
order by flights_count desc


-- 6. Выведите количество пассажиров по каждому коду сотового оператора, если учесть, что код оператора - это три символа после +7


with operator_code as (
    select substring((contact_data ->> 'phone')::text, 3, 3) as operator_code
    from tickets t
)
select operator_code, count(*) as passengers_count
from operator_code
group by operator_code
order by passengers_count desc 

-- 7. Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
------До 50 млн - low
------От 50 млн включительно до 150 млн - middle
------От 150 млн включительно - high
------Выведите в результат количество маршрутов в каждом полученном классе.

with route_coast as (
    select 
    	f.departure_airport, f.arrival_airport, 
    	sum(tf.amount) as total
    from flights f
    join ticket_flights tf on tf.flight_id  = f.flight_id 
    group by f.departure_airport, f.arrival_airport
),
route_classes as (
    select 
    	departure_airport, arrival_airport, total,
    case
	    when total < 50000000 then 'low'
	    when total >= 50000000 and total < 150000000 then 'middle'
	    else 'high'
        end as classes
    from route_coast
)
select 
	classes, 
	count(*) as route_count
from route_classes
group by classes
order by route_count desc  

-- 8. Вычислите медиану стоимости билетов, медиану размера бронирования и отношение медианы бронирования к медиане стоимости билетов, округленной до сотых.

with ticket_costs as (
  select tf.ticket_no, sum(tf.amount) as cost
  from ticket_flights tf
  group by tf.ticket_no
),
booking_sizes as (
  select b.book_ref, sum(b.total_amount) as size
  from bookings b
  group by b.book_ref
),
median_ticket_cost as (
  select percentile_cont(0.5) within group (order by cost) as cost
  from ticket_costs
),
median_booking_size as (
  select percentile_cont(0.5) within group (order by size) as size
  from booking_sizes
)
select 
  (select cost from median_ticket_cost) as median_ticket_cost,
  (select size from median_booking_size) as median_booking_size,
  round((select size from median_booking_size)::numeric / (select cost from median_ticket_cost)::numeric, 2) as ratio
 


-- 9. Найдите значение минимальной стоимости полета 1 км для пассажиров. То есть нужно найти расстояние между аэропортами и с учетом стоимости билетов получить искомый результат.
------Для поиска расстояния между двумя точка на поверхности Земли нужно использовать дополнительный модуль earthdistance (https://postgrespro.ru/docs/postgresql/15/earthdistance).
----- Для работы данного модуля нужно установить еще один модуль cube (https://postgrespro.ru/docs/postgresql/15/cube). 
------Установка дополнительных модулей происходит через оператор create extension название_модуля.
------Функция earth_distance возвращает результат в метрах.
------В облачной базе данных модули уже установлены.

with flight_distances as (
select f.flight_id,
((point(a1.longitude, a1.latitude) <@> point(a2.longitude, a2.latitude)) * 1.60934) as distance_km
from flights f
join airports a1 on f.departure_airport = a1.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code 
),
ticket_flight_costs as (
select (tf.amount / fd.distance_km) as cost_per_km
from ticket_flights tf
join flight_distances fd on tf.flight_id = fd.flight_id
)
select min(cost_per_km) as min_cost_per_km
from ticket_flight_costs





