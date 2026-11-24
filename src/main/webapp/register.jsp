<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%--
	Author: Htet Yamin Aung (P2535607)
	Description: ST0510/JAD Assignment 1 - Create a participant account (public sign-up)

	This form submits to ITSELF (action="register.jsp"):
	    - first visit (GET)       -> just show the empty form
	    - submitted (POST), bad   -> show the form again with the user's typing kept
	                                 and an error under each wrong field
	    - submitted (POST), good  -> save via the register_participant stored procedure,
	                                 then redirect to login.jsp?msg=registered
	Passwords are hashed with bcrypt (jBCrypt jar in WEB-INF/lib) before they are stored.
--%>

<%
	// values to put back into the form (empty on the first visit)
	// passwords are never put back into the page
	String username = "";
	String fullName = "";
	String contactNum = "";
	String email = "";

	// one error message per field (null means the field has no error)
	String usernameErr = null;
	String fullNameErr = null;
	String contactNumErr = null;
	String emailErr = null;
	String passwordErr = null;
	String confirmErr = null;
	
	//form error: not about one field
	String formErr = null;   

	// only run the checks when the form was submitted (when the request method is POST)
	if ("POST".equals(request.getMethod())) {

		// capture the parameter values
		String usernameIn = request.getParameter("username");
		String fullNameIn = request.getParameter("fullName");
		String contactNumIn = request.getParameter("contactNum");
		String emailIn = request.getParameter("email");
		String password = request.getParameter("password");
		String confirmPassword = request.getParameter("confirmPassword");

		// check for null: if any of the required fields is missing from the request, print the error msg
		if (usernameIn == null || fullNameIn == null || contactNumIn == null || emailIn == null
				|| password == null || confirmPassword == null) {
			formErr = "Please fill in all the required fields to proceed.";
		} else {

			// remove whitespace around the values and reassign the variables
			// for password, whitespace is a valid character so it is NOT trimmed
			// .trim() to remove spaces at the start and end
			username = usernameIn.trim();
			
			//for fullName, replace multiple spaces in a row with a single space eg. Alice    Wang will become Alice Wang
			fullName = fullNameIn.trim().replaceAll("\\s+", " ");  
					
			//for contactNum, remove all spaces in between
			contactNum = contactNumIn.trim().replace(" ", "");            // "8123 4567" -> "81234567"
			email = emailIn.trim();

			// ----- username -----
			if (username.isEmpty()) {
				usernameErr = "Username cannot be empty.";
			} else if (!username.matches("[A-Za-z0-9_]{3,20}")) {
				usernameErr = "Username must be 3-20 letters long, and contain only numbers or underscores (no spaces).";
			}

			// ----- full name -----
			if (fullName.isEmpty()) {
				fullNameErr = "Full name cannot be empty.";
			} else if (!fullName.matches("[A-Za-z][A-Za-z '\\-]{1,99}")) {
				fullNameErr = "Use 2-100 letters. Spaces, hyphens and apostrophes are allowed.";
			}

			// ----- contact number (Singapore: 8 digits starting with 6, 8 or 9) -----
			//------we will not store the country code +65
			if (contactNum.isEmpty()) {
				contactNumErr = "Contact number cannot be empty.";
			} else if (!contactNum.matches("[689][0-9]{7}")) {
				contactNumErr = "Enter an 8-digit Singapore phone number starting with 6, 8 or 9. No country code is needed.";
			}

			// ----- email -----
			if (email.isEmpty()) {
				emailErr = "Email cannot be empty.";
			} else if (email.length() > 255 || !email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")) {
				emailErr = "Enter a valid email address, like name@example.com."; //255 is the email column size
			}

			// ----- password -----
			// password.trim() is  used for empty check, so a password of only spaces counts as empty
			//check for strength and length
			if (password.trim().isEmpty()) {
				passwordErr = "Password cannot be empty.";
			} else if (password.length() < 8 || password.length() > 64) {
				passwordErr = "Password must be 8-64 characters.";
			} else if (!password.matches("(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,64}")) {
				passwordErr = "Password must be 8-64 characters and contain at least one uppercase letter, one lowercase letter, one number and one symbol.";
			}

			// ----- confirm password -----
			//empty check and whether it matches the typed password
			if (confirmPassword.isEmpty()) {
				confirmErr = "Please type your password again.";
			} else if (!confirmPassword.equals(password)) {
				confirmErr = "Passwords do not match.";
			}

			//check if there is no error in all fields
			boolean allValid = usernameErr == null && fullNameErr == null && contactNumErr == null
					&& emailErr == null && passwordErr == null && confirmErr == null;

			// only touch the database when every field passed
			if (allValid) {
				boolean registered = false;
				Connection conn = null;

				try {
					// Step 1: Load JDBC Driver
					Class.forName("com.mysql.cj.jdbc.Driver");

					// Step 2: Read the connection details from WEB-INF/.env
					Dotenv dotenv = Dotenv.configure()
							.directory(application.getRealPath("/WEB-INF"))
							.load();
					String connURL = dotenv.get("DB_URL");
					String dbUser = dotenv.get("DB_USERNAME");
					String dbPassword = dotenv.get("DB_PASSWORD");

					// Step 3: Establish connection
					conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

					// Step 4a: is the username already taken? (friendly message instead of a DB error)
					//we use preparedStatement here because username comes from the user input
					PreparedStatement ps = conn.prepareStatement("SELECT user_id FROM users WHERE username = ?");
					ps.setString(1, username);
					ResultSet rs = ps.executeQuery();

					//The rs will contain at most one row as username is UNIQUE so we will use "if" instead of "while"
					if (rs.next()) {        
						usernameErr = "The username is already taken. Please try again with a different username.";
					} else {
						//if the username is not taken
						// Step 4b: hash the password with bcrypt
						// then call the stored procedure that inserts into users AND participants table together
						// the 60-character hash includes its own random salt
						String passwordHash = BCrypt.hashpw(password, BCrypt.gensalt(10));

						CallableStatement cs = conn.prepareCall("{ call register_participant(?, ?, ?, ?, ?) }");
						cs.setString(1, username);
						cs.setString(2, passwordHash);
						cs.setString(3, fullName);
						cs.setString(4, email);
						cs.setString(5, contactNum);

						// Step 5: Execute
						cs.execute();
						registered = true;
					}
				 //error catching
				} catch (SQLIntegrityConstraintViolationException e) {
					// someone took the same username between the username check and the insert (before the insert and after the check)
					System.err.println("register.jsp - " + e);
					usernameErr = "The username is already taken. Please try again with a different username.";
				} catch (Exception e) {
					// we will print details to the console and  a plain sentence to the user
					//because we do not want to reveal the database details to the user
					System.err.println("register.jsp - " + e);
					formErr = "Sorry, we couldn't create your account right now. Please try again later.";
				} finally {
					// Step 7: Close connection
					if (conn != null) {
						try {
							conn.close();
						} catch (SQLException e) {
							System.err.println("Error closing connection :" + e);
						}
					}
				}

				// Step 6: Process result - success goes to the sign-in page
				if (registered) {
					response.sendRedirect("login.jsp?msg=registered");
					return;
				}
			}
		}
	}
%>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>Create account - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
<div class="page">
	<%@ include file="/shared/header.jsp" %>
	<div class="card">
		<h1 class="pageTitle">Create a participant account</h1>

		<%-- form-level message --%>
		<% if (formErr != null) { %>
			<div class="msgBox msgError"><%= formErr %></div>
		<% } %>

		<%-- submits to the same page; novalidate turns off the browser checks --%>
		<%--every field is checked by server-side code --%>
		<%-- the error goes before the grey hint; styles.css hides the hint when an error is shown --%>
		<form action="register.jsp" method="post" novalidate>
			<div class="formGrid">

				<div class="field">
					<label for="username">Username <span class="req">*</span></label>
					<!-- if this field has an error, give the box the inputError class otherwise no class -->
					<input type="text" id="username" name="username" maxlength="20" placeholder="e.g. alex_tan"
						value="<%= escapeHtml(username) %>" class="<%= usernameErr != null ? "inputError" : "" %>">
					<!-- if usernameErr is not null, print the usernameErr inside the class fieldError -->
					<% if (usernameErr != null) { %><div class="fieldError"><%= usernameErr %></div><% } %>
					<div class="fieldHint">Use 3-20 letters, numbers or underscores.</div>
				</div>

				<div class="field">
					<label for="fullName">Full name <span class="req">*</span></label>
					<input type="text" id="fullName" name="fullName" maxlength="100" placeholder="e.g. Alex Tan"
						value="<%= escapeHtml(fullName) %>" class="<%= fullNameErr != null ? "inputError" : "" %>">
					<% if (fullNameErr != null) { %><div class="fieldError"><%= fullNameErr %></div><% } %>
					<div class="fieldHint">Enter your full name.</div>
				</div>

				<div class="field">
					<label for="contact">Contact number <span class="req">*</span></label>
					<input type="text" id="contact" name="contactNum" maxlength="9" placeholder="e.g. 9123 4567"
						value="<%= escapeHtml(contactNum) %>" class="<%= contactNumErr != null ? "inputError" : "" %>">
					<% if (contactNumErr != null) { %><div class="fieldError"><%= contactNumErr %></div><% } %>
					<div class="fieldHint">8-digit Singapore number starting with 6, 8 or 9.</div>
				</div>

				<div class="field">
					<label for="email">Email <span class="req">*</span></label>
					<input type="text" id="email" name="email" maxlength="255" placeholder="name@example.com"
						value="<%= escapeHtml(email) %>" class="<%= emailErr != null ? "inputError" : "" %>">
					<% if (emailErr != null) { %><div class="fieldError"><%= emailErr %></div><% } %>
				</div>

				<div class="field">
					<label for="password">Password <span class="req">*</span></label>
					<input type="password" id="password" name="password" maxlength="64"
						class="<%= passwordErr != null ? "inputError" : "" %>">
					<% if (passwordErr != null) { %><div class="fieldError"><%= passwordErr %></div><% } %>
					<div class="fieldHint">8-64 characters, with uppercase, lowercase, number and symbol.</div>
				</div>

				<div class="field">
					<label for="confirmPassword">Confirm password <span class="req">*</span></label>
					<input type="password" id="confirmPassword" name="confirmPassword" maxlength="64"
						class="<%= confirmErr != null ? "inputError" : "" %>">
					<% if (confirmErr != null) { %><div class="fieldError"><%= confirmErr %></div><% } %>
				</div>

			</div>

			<div class="formActions">
				<span>Already have an account? <a href="login.jsp">Sign in</a></span>
				<input type="submit" class="btn btnPrimary" value="Create account">
			</div>
		</form>
	</div>

</div>
</body>
</html>
