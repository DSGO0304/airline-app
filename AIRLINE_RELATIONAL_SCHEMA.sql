
CREATE TABLE Airport (
    iata_code CHAR(3) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    city VARCHAR(50)
);


CREATE TABLE Airline (
    airline_id SERIAL PRIMARY KEY,
    iata_code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL
);


CREATE TABLE Customer (
    customer_email VARCHAR(100) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    home_airport_id CHAR(3) REFERENCES Airport(iata_code)
);


CREATE TABLE Address (
    address_id SERIAL PRIMARY KEY,
    street VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    country VARCHAR(50) NOT NULL,
    zipcode VARCHAR(10),
    customer_email VARCHAR(100) NOT NULL REFERENCES Customer(customer_email)
);


CREATE TABLE Credit_Card (
    card_id SERIAL PRIMARY KEY,
    card_number VARCHAR(16) NOT NULL,
    expiration_date DATE NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    customer_email VARCHAR(100) NOT NULL REFERENCES Customer(customer_email),
    billing_address_id INT REFERENCES Address(address_id)
);

CREATE TABLE Flight (
    flight_id SERIAL PRIMARY KEY,
    flight_number VARCHAR(10) NOT NULL,
    flight_date DATE NOT NULL,
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    first_class_capacity INT NOT NULL,
    economy_class_capacity INT NOT NULL,
    airline_id INT NOT NULL REFERENCES Airline(airline_id),
    departure_airport CHAR(3) NOT NULL REFERENCES Airport(iata_code),
    arrival_airport CHAR(3) NOT NULL REFERENCES Airport(iata_code)
);


CREATE TABLE Price (
    price_id SERIAL PRIMARY KEY,
    flight_id INT NOT NULL REFERENCES Flight(flight_id),
    class_type VARCHAR(10) NOT NULL CHECK (class_type IN ('ECONOMY', 'FIRST')),
    amount DECIMAL(10,2) NOT NULL,
    UNIQUE (flight_id, class_type)
); 


CREATE OR REPLACE FUNCTION check_first_class_price()
RETURNS TRIGGER AS $$
DECLARE
    other_amount DECIMAL(10,2);
BEGIN
    IF NEW.class_type = 'FIRST' THEN
        SELECT amount INTO other_amount
        FROM Price
        WHERE flight_id = NEW.flight_id AND class_type = 'ECONOMY';

        IF FOUND AND NEW.amount <= other_amount THEN
            RAISE EXCEPTION 'First class price must be greater than Economy price for flight %', NEW.flight_id;
        END IF;

    ELSIF NEW.class_type = 'ECONOMY' THEN
        SELECT amount INTO other_amount
        FROM Price
        WHERE flight_id = NEW.flight_id AND class_type = 'FIRST';

        IF FOUND AND NEW.amount >= other_amount THEN
            RAISE EXCEPTION 'Economy price must be less than First class price for flight %', NEW.flight_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_first_class_price
BEFORE INSERT OR UPDATE ON Price
FOR EACH ROW EXECUTE FUNCTION check_first_class_price();


CREATE TABLE Booking (
    booking_id SERIAL PRIMARY KEY,
    booking_date DATE NOT NULL,
    booking_status VARCHAR(20) NOT NULL CHECK (booking_status IN ('CONFIRMED', 'CANCELLED')),
    customer_email VARCHAR(100) NOT NULL REFERENCES Customer(customer_email),
    card_id INT NOT NULL REFERENCES Credit_Card(card_id)
);

CREATE TABLE Booking_Flight (
    booking_flight_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES Booking(booking_id),
    flight_id INT NOT NULL REFERENCES Flight(flight_id),
    class_type VARCHAR(10) NOT NULL CHECK (class_type IN ('ECONOMY', 'FIRST')),
    UNIQUE (booking_id, flight_id)
);


CREATE TABLE Aircraft (
    aircraft_id SERIAL PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    total_seats INT NOT NULL,
    airline_id INT NOT NULL REFERENCES Airline(airline_id)
);


CREATE TABLE Passenger (
    passenger_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    phone VARCHAR(20),
    nationality VARCHAR(50),
    passport_number VARCHAR(20),
    gender VARCHAR(10),
    customer_email VARCHAR(100) REFERENCES Customer(customer_email)
);


CREATE TABLE Ticket (
    ticket_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES Booking(booking_id),
    pnr VARCHAR(20) NOT NULL,
    seat_number VARCHAR(10),
    class_type VARCHAR(10) NOT NULL CHECK (class_type IN ('ECONOMY', 'FIRST')),
    checked_bags INT DEFAULT 0
);


CREATE INDEX idx_flight_date ON Flight(flight_date);
CREATE INDEX idx_flight_departure ON Flight(departure_airport);
CREATE INDEX idx_flight_arrival ON Flight(arrival_airport);
CREATE INDEX idx_booking_customer ON Booking(customer_email);
CREATE INDEX idx_booking_flight ON Booking_Flight(booking_id);


--1. AIRPORTS
INSERT INTO Airport (iata_code, name, country, state, city) VALUES
('ORD', 'O''Hare International Airport',        'USA', 'Illinois',   'Chicago'),
('JFK', 'John F. Kennedy International Airport', 'USA', 'New York',   'New York City'),
('LAX', 'Los Angeles International Airport',     'USA', 'California', 'Los Angeles'),
('MIA', 'Miami International Airport',           'USA', 'Florida',    'Miami'),
('CDG', 'Charles de Gaulle Airport',             'France', NULL,      'Paris'),
('LHR', 'Heathrow Airport',                      'UK',     NULL,      'London');
 
-- 2. AIRLINES
INSERT INTO Airline (iata_code, name, country) VALUES
('AA', 'American Airlines', 'USA'),
('UA', 'United Airlines',   'USA'),
('BA', 'British Airways',   'UK'),
('AF', 'Air France',        'France');
 
-- 3. CUSTOMERS
INSERT INTO Customer (customer_email, name, home_airport_id) VALUES
('sofia.garcia@email.com',   'Sofia Garcia',   'ORD'),
('james.smith@email.com',    'James Smith',    'JFK'),
('emily.chen@email.com',     'Emily Chen',     'LAX'),
('carlos.reyes@email.com',   'Carlos Reyes',   'MIA');
 
-- 4. ADDRESSES
INSERT INTO Address (street, city, state, country, zipcode, customer_email) VALUES
('3300 S Federal St',   'Chicago',      'Illinois',   'USA', '60616', 'sofia.garcia@email.com'),
('120 Broadway',        'New York City','New York',   'USA', '10005', 'james.smith@email.com'),
('1 Infinite Loop',     'Cupertino',    'California', 'USA', '95014', 'emily.chen@email.com'),
('800 Brickell Ave',    'Miami',        'Florida',    'USA', '33131', 'carlos.reyes@email.com');
 
-- 5. CREDIT CARDS (billing_address_id references Address rows 1-4)
INSERT INTO Credit_Card (card_number, expiration_date, card_type, customer_email, billing_address_id) VALUES
('4111111111111111', '2027-08-31', 'VISA',       'sofia.garcia@email.com',  1),
('5500005555555559', '2026-12-31', 'MASTERCARD', 'james.smith@email.com',   2),
('378282246310005',  '2028-03-31', 'AMEX',       'emily.chen@email.com',    3),
('6011111111111117', '2027-06-30', 'DISCOVER',   'carlos.reyes@email.com',  4);
 
-- 6. FLIGHTS
INSERT INTO Flight (flight_number, flight_date, departure_time, arrival_time,
                    first_class_capacity, economy_class_capacity,
                    airline_id, departure_airport, arrival_airport) VALUES
('AA101',  '2026-05-10', '08:00', '11:30',  16, 150, 1, 'ORD', 'JFK'),
('UA205',  '2026-05-10', '09:15', '12:00',  20, 180, 2, 'JFK', 'LAX'),
('BA7001', '2026-05-12', '18:00', '06:30',  40, 260, 3, 'JFK', 'LHR'),
('AF0023', '2026-05-15', '11:45', '05:00',  36, 220, 4, 'MIA', 'CDG'),
('AA340',  '2026-05-20', '14:00', '16:45',  12, 130, 1, 'LAX', 'ORD');
 
-- 7. PRICES
INSERT INTO Price (flight_id, class_type, amount) VALUES
(1, 'ECONOMY', 189.00),
(1, 'FIRST',   549.00),
(2, 'ECONOMY', 210.00),
(2, 'FIRST',   680.00),
(3, 'ECONOMY', 620.00),
(3, 'FIRST',  2100.00),
(4, 'ECONOMY', 750.00),
(4, 'FIRST',  3200.00),
(5, 'ECONOMY', 175.00),
(5, 'FIRST',   499.00);
 
-- 8. BOOKINGS
INSERT INTO Booking (booking_date, booking_status, customer_email, card_id) VALUES
('2026-04-01', 'CONFIRMED',  'sofia.garcia@email.com',  1),
('2026-04-03', 'CONFIRMED',  'james.smith@email.com',   2),
('2026-04-05', 'CANCELLED',  'emily.chen@email.com',    3),
('2026-04-10', 'CONFIRMED',  'carlos.reyes@email.com',  4),
('2026-04-12', 'CONFIRMED',  'sofia.garcia@email.com',  1);
 
-- 9. BOOKING_FLIGHTS
INSERT INTO Booking_Flight (booking_id, flight_id, class_type) VALUES
(1, 1, 'ECONOMY'),   -- Sofia: ORD -> JFK
(2, 2, 'FIRST'),     -- James: JFK -> LAX
(3, 3, 'ECONOMY'),   -- Emily: JFK -> LHR (cancelled)
(4, 4, 'FIRST'),     -- Carlos: MIA -> CDG
(5, 5, 'ECONOMY');   -- Sofia: LAX -> ORD
 
-- 10. AIRCRAFT
INSERT INTO Aircraft (model, total_seats, airline_id) VALUES
('Boeing 737-800',   166, 1),
('Boeing 787-9',     296, 2),
('Airbus A380',      469, 3),
('Airbus A330-200',  256, 4),
('Boeing 777-300ER', 396, 1);
 
-- 11. PASSENGERS
INSERT INTO Passenger (first_name, last_name, email, date_of_birth, phone,
                        nationality, passport_number, gender, customer_email) VALUES
('Sofia',   'Garcia',  'sofia.garcia@email.com',  '2002-03-15', '312-555-0101', 'American', 'US123456789', 'Female', 'sofia.garcia@email.com'),
('James',   'Smith',   'james.smith@email.com',   '1995-07-22', '212-555-0202', 'American', 'US987654321', 'Male',   'james.smith@email.com'),
('Emily',   'Chen',    'emily.chen@email.com',    '1998-11-03', '310-555-0303', 'American', 'US456789123', 'Female', 'emily.chen@email.com'),
('Carlos',  'Reyes',   'carlos.reyes@email.com',  '1990-01-30', '305-555-0404', 'American', 'US321654987', 'Male',   'carlos.reyes@email.com'),
('Liam',    'Johnson', 'liam.johnson@email.com',  '1988-06-14', '415-555-0505', 'British',  'GB112233445', 'Male',   NULL);
 
-- 12. TICKETS
INSERT INTO Ticket (booking_id, pnr, seat_number, class_type, checked_bags) VALUES
(1, 'PNR001AAX', '22A', 'ECONOMY', 1),
(2, 'PNR002UAX', '3B',  'FIRST',   2),
(3, 'PNR003BAX', '35C', 'ECONOMY', 1),
(4, 'PNR004AFX', '2A',  'FIRST',   3),
(5, 'PNR005AAX', '18D', 'ECONOMY', 0); 