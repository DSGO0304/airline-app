from flask import Flask, render_template, request, redirect, session
from db import get_connection

app = Flask(__name__)
app.secret_key = 'airline123'

# ── HOME ──────────────────────────────────────────
@app.route('/')
def home():
    return render_template('register.html')

# ── REGISTER ──────────────────────────────────────
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        name        = request.form['name']
        email       = request.form['email']
        home_airport = request.form['home_airport'].upper() or None

        try:
            conn = get_connection()
            cur  = conn.cursor()
            cur.execute(
                "INSERT INTO Customer (customer_email, name, home_airport_id) VALUES (%s, %s, %s)",
                (email, name, home_airport)
            )
            conn.commit()
            cur.close()
            conn.close()
            session['email'] = email
            return redirect('/dashboard')
        except Exception as e:
            return render_template('register.html', error=str(e))

    return render_template('register.html')

# ── DASHBOARD  ───────────────────────────
@app.route('/dashboard')
def dashboard():
    if 'email' not in session:
        return redirect('/login')
    return render_template('dashboard.html', email=session['email'])

#--LOGOUT---------------------
@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')

#login 
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        try:
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT * FROM customer WHERE customer_email =%s", (email,) )
            customer = cur.fetchone()
            cur .close()
            conn.close()
            if customer :
                session['email'] = email 
                return redirect('/dashboard')
            else:
                return render_template('login.html' , error = 'Email not found. Please register first. ')
        except Exception as e:
            return render_template('login.html', error=str (e))
    return render_template('login.html')
#SEARCH-------------------------------------------------
@app.route('/search' , methods = ['GET', 'POST'])
def search():
    if 'email' not in session: 
        return redirect('/login')
    
    flights = []
    searched = False
    class_type = 'ECONOMY'

    if request.method == 'POST':
        departure = request.form['departure'].upper()
        arrival = request.form['arrival'].upper()
        date = request.form['date']
        class_type = request.form['class_type']
        searched = True

        try:
            conn = get_connection()
            cur = conn.cursor()
            cur.execute(
                """
                SELECT f.flight_number, f.departure_airport, f.arrival_airport,
                       f.departure_time, f.arrival_time, p.amount, f.flight_id
                FROM Flight f
                JOIN Price p ON f.flight_id = p.flight_id
                WHERE f.departure_airport = %s
                  AND f.arrival_airport = %s
                  AND f.flight_date = %s
                  AND p.class_type = %s
                """,
                (departure, arrival, date, class_type)
            )
            flights = cur.fetchall()
            cur.close()
            conn.close()
        except Exception as e:
            return render_template('search.html', error=str(e))
    return render_template('search.html', flights=flights, searched=searched, class_type=class_type)

@app.route('/book/<int:flight_id>/<class_type>', methods=['GET', 'POST'])
def book(flight_id, class_type):
    if 'email' not in session:
        return redirect('/login')
    email = session['email']
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("""
            SELECT f.flight_id, f.flight_number, f.flight_date,
                   f.departure_airport, f.arrival_airport,
                   f.departure_time, f.arrival_time
            FROM Flight f WHERE f.flight_id = %s
        """, (flight_id,))
        flight = cur.fetchone()
        cur.execute("SELECT amount FROM Price WHERE flight_id = %s AND class_type = %s",
                    (flight_id, class_type))
        price = cur.fetchone()[0]
        cur.execute("SELECT card_id, card_type, card_number FROM Credit_Card WHERE customer_email = %s",
                    (email,))
        cards = cur.fetchall()
        if request.method == 'POST':
            card_id = request.form['card_id']
            cur.execute("""
                INSERT INTO Booking (booking_date, booking_status, customer_email, card_id)
                VALUES (CURRENT_DATE, 'CONFIRMED', %s, %s)
                RETURNING booking_id
            """, (email, card_id))
            booking_id = cur.fetchone()[0]
            cur.execute("INSERT INTO Booking_Flight (booking_id, flight_id, class_type) VALUES (%s, %s, %s)",
                        (booking_id, flight_id, class_type))
            conn.commit()
            cur.close()
            conn.close()
            return redirect('/my-bookings')
        cur.close()
        conn.close()
        return render_template('booking.html', flight=flight, class_type=class_type,
                               price=price, cards=cards)
    except Exception as e:
        return render_template('booking.html', error=str(e))
    
    # ── MY BOOKINGS ───────────────────────────────────
@app.route('/my-bookings')
def my_bookings():
    if 'email' not in session:
        return redirect('/login')
    email = session['email']
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("""
            SELECT b.booking_id, f.flight_number, f.departure_airport,
                   f.arrival_airport, f.flight_date, bf.class_type, b.booking_status
            FROM Booking b
            JOIN Booking_Flight bf ON b.booking_id = bf.booking_id
            JOIN Flight f ON bf.flight_id = f.flight_id
            WHERE b.customer_email = %s
            ORDER BY b.booking_date DESC
        """, (email,))
        bookings = cur.fetchall()
        cur.close()
        conn.close()
        return render_template('my_bookings.html', bookings=bookings)
    except Exception as e:
        return render_template('my_bookings.html', error=str(e))

# ── CANCEL BOOKING ────────────────────────────────
@app.route('/cancel/<int:booking_id>')
def cancel(booking_id):
    if 'email' not in session:
        return redirect('/login')
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("UPDATE Booking SET booking_status = 'CANCELLED' WHERE booking_id = %s",
                    (booking_id,))
        conn.commit()
        cur.close()
        conn.close()
        return redirect('/my-bookings')
    except Exception as e:
        return redirect('/my-bookings')

# ── ACCOUNT ───────────────────────────────────────
@app.route('/account')
def account():
    if 'email' not in session:
        return redirect('/login')
    email = session['email']
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("SELECT * FROM Address WHERE customer_email = %s", (email,))
        addresses = cur.fetchall()
        cur.execute("SELECT card_id, card_type, card_number, expiration_date FROM Credit_Card WHERE customer_email = %s", (email,))
        cards = cur.fetchall()
        cur.close()
        conn.close()
        return render_template('account.html', addresses=addresses, cards=cards)
    except Exception as e:
        return render_template('account.html', error=str(e))

# ── ADD ADDRESS ───────────────────────────────────
@app.route('/add-address', methods=['POST'])
def add_address():
    if 'email' not in session:
        return redirect('/login')
    email   = session['email']
    street  = request.form['street']
    city    = request.form['city']
    state   = request.form['state'] or None
    country = request.form['country']
    zipcode = request.form['zipcode'] or None
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("INSERT INTO Address (street, city, state, country, zipcode, customer_email) VALUES (%s, %s, %s, %s, %s, %s)",
                    (street, city, state, country, zipcode, email))
        conn.commit()
        cur.close()
        conn.close()
        return redirect('/account')
    except Exception as e:
        return redirect('/account')

# ── DELETE ADDRESS ────────────────────────────────
@app.route('/delete-address/<int:address_id>')
def delete_address(address_id):
    if 'email' not in session:
        return redirect('/login')
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("DELETE FROM Address WHERE address_id = %s", (address_id,))
        conn.commit()
        cur.close()
        conn.close()
        return redirect('/account')
    except Exception as e:
        return redirect('/account')

# ── ADD CARD ──────────────────────────────────────
@app.route('/add-card', methods=['POST'])
def add_card():
    if 'email' not in session:
        return redirect('/login')
    email           = session['email']
    card_number     = request.form['card_number']
    card_type       = request.form['card_type'].upper()
    expiration_date = request.form['expiration_date']
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("INSERT INTO Credit_Card (card_number, expiration_date, card_type, customer_email) VALUES (%s, %s, %s, %s)",
                    (card_number, expiration_date, card_type, email))
        conn.commit()
        cur.close()
        conn.close()
        return redirect('/account')
    except Exception as e:
        return redirect('/account')

# ── DELETE CARD
@app.route('/delete-card/<int:card_id>')
def delete_card(card_id):
    if 'email' not in session:
        return redirect('/login')
    try:
        conn = get_connection()
        cur  = conn.cursor()
        cur.execute("DELETE FROM Credit_Card WHERE card_id = %s", (card_id,))
        conn.commit()
        cur.close()
        conn.close()
        return redirect('/account')
    except Exception as e:
        return redirect('/account')


if __name__ == '__main__':
    app.run(debug=True, port=5001)