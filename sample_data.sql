
INSERT INTO Airport (iata_code, name, country, state, city) VALUES
('ORD', 'O''Hare International Airport',        'USA', 'Illinois',   'Chicago'),
('JFK', 'John F. Kennedy International Airport', 'USA', 'New York',   'New York City'),
('LAX', 'Los Angeles International Airport',     'USA', 'California', 'Los Angeles'),
('MIA', 'Miami International Airport',           'USA', 'Florida',    'Miami'),
('CDG', 'Charles de Gaulle Airport',             'France', NULL,      'Paris'),
('LHR', 'Heathrow Airport',                      'UK',     NULL,      'London');


INSERT INTO Airline (iata_code, name, country) VALUES
('AA', 'American Airlines', 'USA'),
('UA', 'United Airlines',   'USA'),
('BA', 'British Airways',   'UK'),
('AF', 'Air France',        'France');


INSERT INTO Customer (customer_email, name, home_airport_id) VALUES
('sofia.garcia@email.com',   'Sofia Garcia',   'ORD'),
('james.smith@email.com',    'James Smith',    'JFK'),
('emily.chen@email.com',     'Emily Chen',     'LAX'),
('carlos.reyes@email.com',   'Carlos Reyes',   'MIA');


INSERT INTO Address (street, city, state, country, zipcode, customer_email) VALUES
('3300 S Federal St',   'Chicago',      'Illinois',   'USA', '60616', 'sofia.garcia@email.com'),
('120 Broadway',        'New York City','New York',   'USA', '10005', 'james.smith@email.com'),
('1 Infinite Loop',     'Cupertino',    'California', 'USA', '95014', 'emily.chen@email.com'),
('800 Brickell Ave',    'Miami',        'Florida',    'USA', '33131', 'carlos.reyes@email.com');


INSERT INTO Credit_Card (card_number, expiration_date, card_type, customer_email, billing_address_id) VALUES
('4111111111111111', '2027-08-31', 'VISA',       'sofia.garcia@email.com',  1),
('5500005555555559', '2026-12-31', 'MASTERCARD', 'james.smith@email.com',   2),
('378282246310005',  '2028-03-31', 'AMEX',       'emily.chen@email.com',    3),
('6011111111111117', '2027-06-30', 'DISCOVER',   'carlos.reyes@email.com',  4);


INSERT INTO Flight (flight_number, flight_date, departure_time, arrival_time,
                    first_class_capacity, economy_class_capacity,
                    airline_id, departure_airport, arrival_airport) VALUES
('AA101',  '2026-05-10', '08:00', '11:30',  16, 150, 1, 'ORD', 'JFK'),
('UA205',  '2026-05-10', '09:15', '12:00',  20, 180, 2, 'JFK', 'LAX'),
('BA7001', '2026-05-12', '18:00', '06:30',  40, 260, 3, 'JFK', 'LHR'),
('AF0023', '2026-05-15', '11:45', '05:00',  36, 220, 4, 'MIA', 'CDG'),
('AA340',  '2026-05-20', '14:00', '16:45',  12, 130, 1, 'LAX', 'ORD'),
('AA102',  '2026-05-15', '14:00', '17:30',  16, 150, 1, 'JFK', 'ORD'),
('UA206',  '2026-05-18', '10:00', '14:00',  20, 180, 2, 'ORD', 'LAX');


INSERT INTO Price (flight_id, class_type, amount) VALUES
(1, 'ECONOMY', 189.00), (1, 'FIRST',   549.00),
(2, 'ECONOMY', 210.00), (2, 'FIRST',   680.00),
(3, 'ECONOMY', 620.00), (3, 'FIRST',  2100.00),
(4, 'ECONOMY', 750.00), (4, 'FIRST',  3200.00),
(5, 'ECONOMY', 175.00), (5, 'FIRST',   499.00),
(6, 'ECONOMY', 199.00), (6, 'FIRST',   599.00),
(7, 'ECONOMY', 220.00), (7, 'FIRST',   700.00);


INSERT INTO Booking (booking_date, booking_status, customer_email, card_id) VALUES
('2026-04-01', 'CONFIRMED',  'sofia.garcia@email.com',  1),
('2026-04-03', 'CONFIRMED',  'james.smith@email.com',   2),
('2026-04-05', 'CANCELLED',  'emily.chen@email.com',    3),
('2026-04-10', 'CONFIRMED',  'carlos.reyes@email.com',  4),
('2026-04-12', 'CONFIRMED',  'sofia.garcia@email.com',  1);


INSERT INTO Booking_Flight (booking_id, flight_id, class_type) VALUES
(1, 1, 'ECONOMY'),
(2, 2, 'FIRST'),
(3, 3, 'ECONOMY'),
(4, 4, 'FIRST'),
(5, 5, 'ECONOMY');