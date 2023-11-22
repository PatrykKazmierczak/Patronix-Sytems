from flask import Flask, render_template, redirect, url_for, flash, request
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Length, EqualTo
from werkzeug.security import generate_password_hash, check_password_hash
from flask_sqlalchemy import SQLAlchemy
import secrets
import subprocess

app = Flask(__name__)
app.config['SECRET_KEY'] = secrets.token_hex(16)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db'  # Use SQLite for simplicity

db = SQLAlchemy(app)

class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(30), unique=True, nullable=False)
    password = db.Column(db.String(60), nullable=False)

class ScriptOutput(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    output = db.Column(db.String(500))

class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(), Length(min=4, max=30)])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Log In')

class RegisterForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(), Length(min=4, max=30)])
    password = PasswordField('Password', validators=[DataRequired()])
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register')

login_manager = LoginManager(app)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))
    
@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user and check_password_hash(user.password, form.password.data):
            login_user(user)
            next_page = request.args.get('next')
            return redirect(next_page) if next_page else redirect(url_for('dashboard'))
        else:
            flash('User does not exist. Please register first.', 'danger')
            return redirect(url_for('register'))
    return render_template('login.html', title='Login', login_form=form)

@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegisterForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user:
            flash('User already exists. Please login.')
        else:
            hashed_password = generate_password_hash(form.password.data, method='pbkdf2:sha256')
            new_user = User(username=form.username.data, password=hashed_password)
            db.session.add(new_user)
            db.session.commit()
            login_user(new_user)
            return redirect(url_for('dashboard'))
    return render_template('register.html', register_form=form)

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))  # Redirect to 'login' route after logout

@app.route('/')
def home():
    return redirect(url_for('login'))

@app.route('/run_first_script')
@login_required
def run_first_script():
    # Run the first PowerShell script and capture the output
    result = subprocess.run(["powershell.exe", "./scripts/Get-ADComputersExportToSQL.ps1"], shell=True, capture_output=True, text=True)

    # Create a new model instance with the script output
    model_instance = ScriptOutput(output=result.stdout)

    # Add the new model instance to the session and commit it to the database
    db.session.add(model_instance)
    db.session.commit()

    return redirect(request.referrer)

@app.route('/run_second_script')
@login_required
def run_second_script():
    # Run the second PowerShell script and capture the output
    result = subprocess.run(["powershell.exe", "./sripts/Get-ADUsersExportToSQLOnPremUpdate.ps1"], shell=True, capture_output=True, text=True)

    # Create a new model instance with the script output
    model_instance = ScriptOutput(output=result.stdout)

    # Add the new model instance to the session and commit it to the database
    db.session.add(model_instance)
    db.session.commit()

    return redirect(request.referrer)

# ... the rest of your Flask app code ...

@app.route('/dashboard')
@login_required
def dashboard():
    # Query the ScriptOutput table
    script_outputs = ScriptOutput.query.all()
    return render_template('dashboard.html', script_outputs=script_outputs)

# ... the rest of your Flask app code ...

if __name__ == '__main__':
    with app.app_context():
        db.create_all()  # Create database if it does not exist
    app.run(host='0.0.0.0', port=8000, debug=True)