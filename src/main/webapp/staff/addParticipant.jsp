<%--
Author: Htet Yamin Aung (P2535607)
Date: 23/11/2026
Description: ST0510/JAD Assignment 1 - Staff: add a participant account

This form submits to ITSELF (action="addParticipant.jsp"):
	- first visit (GET)       -> show the empty form
	- submitted (POST), bad   -> show the form again with the typing kept and an error under each wrong field
	- submitted (POST), good  -> save via the register_participant stored procedure,
	                             then redirect to listParticipants.jsp?msg=added
Passwords are hashed with bcrypt before they are stored.
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%-- fragments kept in WEB-INF so they cannot be opened directly --%>
<%@ include file="/auth/staffGuard.jsp" %>
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

	// form error: not about one field
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

		// check for null: if any of the required fields is missing from the request
		if (usernameIn == null || fullNameIn == null || contactNumIn == null || emailIn == null
				|| password == null || confirmPassword == null) {
			formErr = "Please fill in all the required fields to proceed.";
		} else {

			// remove spaces at the start and end; the password is NOT trimmed (spaces are valid in it)
			username = usernameIn.trim();

			// for fullName, also replace multiple spaces in a row with a single space
			fullName = fullNameIn.trim().replaceAll("\\s+", " ");

			// for contactNum, remove all spaces in between, e.g. "8123 4567" -> "81234567"
			contactNum = contactNumIn.trim().replace(" ", "");
			email = emailIn.trim();

			// ----- username -----
			if (username.isEmpty()) {
				usernameErr = "Username cannot be empty.";
			} else if (!username.matches("[A-Za-z0-9_]{3,20}")) {
				usernameErr = "Username must be 3-20 characters long, using only letters, numbers or underscores (no spaces).";
			}

			// ----- full name -----
			if (fullName.isEmpty()) {
				fullNameErr = "Full name cannot be empty.";
			} else if (!fullName.matches("[A-Za-z][A-Za-z '\\-]{1,99}")) {
				fullNameErr = "Use 2-100 letters. Spaces, hyphens and apostrophes are allowed.";
			}

			// ----- contact number (Singapore: 8 digits starting with 6, 8 or 9, no +65) -----
			if (contactNum.isEmpty()) {
				contactNumErr = "Contact number cannot be empty.";
			} else if (!contactNum.matches("[689][0-9]{7}")) {
				contactNumErr = "Enter an 8-digit Singapore phone number starting with 6, 8 or 9. No country code is needed.";
			}

			// ----- email (255 is the email column size) -----
			if (email.isEmpty()) {
				emailErr = "Email cannot be empty.";
			} else if (email.length() > 255 || !email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")) {
				emailErr = "Enter a valid email address, like name@example.com.";
			}

			// ----- password -----
			// password.trim() is only used for the empty check, so a password of only spaces counts as empty
			if (password.trim().isEmpty()) {
				passwordErr = "Password cannot be empty.";
			} else if (password.length() < 8 || password.length() > 64) {
				passwordErr = "Password must be 8-64 characters.";
			} else if (!password.matches("(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,64}")) {
				passwordErr = "Password must contain at least one uppercase letter, one lowercase letter, one number and one symbol.";
			}

			// ----- confirm password -----
			if (confirmPassword.isEmpty()) {
				confirmErr = "Please type the password again.";
			} else if (!confirmPassword.equals(password)) {
				confirmErr = "Passwords do not match.";
			}

			// check if there is no error in all fields
			boolean allValid = usernameErr == null && fullNameErr == null && contactNumErr == null
					&& emailErr == null && passwordErr == null && confirmErr == null;

			if (!allValid) {
				formErr = "Please correct the highlighted fields. Your other entries have been kept.";
			} else {
				// only touch the database when every field passed
				boolean added = false;
				Connection conn = null;

				try {
					// Step 1: Load JDBC Driver
					Class.forName("com.mysql.cj.jdbc.Driver");

					// Step 2: Read connection details from .env in WEB-INF
					Dotenv dotenv = Dotenv.configure().directory(application.getRealPath("/WEB-INF")).load();
					String connURL = dotenv.get("DB_URL");
					String dbUser = dotenv.get("DB_USERNAME");
					String dbPassword = dotenv.get("DB_PASSWORD");

					// Step 3: Establish connection
					conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

					// Step 4a: is the username already taken? (friendly message instead of a database error)
					PreparedStatement ps = conn.prepareStatement("SELECT user_id FROM users WHERE username = ?");
					ps.setString(1, username);
					ResultSet rs = ps.executeQuery();

					// one row at most (username is UNIQUE), so use if instead of while
					if (rs.next()) {
						usernameErr = "The username is already taken. Please try again with a different username.";
						formErr = "Please correct the highlighted fields. Your other entries have been kept.";
					} else {
						// Step 4b: hash the password with bcrypt (the 60-character hash includes its own random salt),
						// then insert into users AND participants together in the stored procedure
						String passwordHash = BCrypt.hashpw(password, BCrypt.gensalt(10));

						CallableStatement cs = conn.prepareCall("{ call register_participant(?, ?, ?, ?, ?) }");
						cs.setString(1, username);
						cs.setString(2, passwordHash);
						cs.setString(3, fullName);
						cs.setString(4, email);
						cs.setString(5, contactNum);

						// Step 5: Execute
						cs.execute();
						added = true;
					}

				} catch (SQLIntegrityConstraintViolationException e) {
					// someone took the same username between the check and the insert
					System.err.println("addParticipant.jsp - duplicate username: " + e);
					usernameErr = "The username is already taken. Please try again with a different username.";
					formErr = "Please correct the highlighted fields. Your other entries have been kept.";
				} catch (ClassNotFoundException e) {
					System.err.println("addParticipant.jsp - driver not found: " + e);
					formErr = "Sorry, the participant couldn't be added right now. Please try again later.";
				} catch (SQLException e) {
					System.err.println("addParticipant.jsp - SQL error: " + e);
					formErr = "Sorry, the participant couldn't be added right now. Please try again later.";
				} catch (DotenvException e) {
					System.err.println("addParticipant.jsp - .env error: " + e);
					formErr = "Sorry, the participant couldn't be added right now. Please try again later.";
				} catch (Exception e) {
					System.err.println("addParticipant.jsp - " + e);
					formErr = "Sorry, the participant couldn't be added right now. Please try again later.";
				} finally {
					// Step 7: Close connection
					if (conn != null) {
						try {
							conn.close();
						} catch (SQLException e) {
							System.err.println("Error closing connection: " + e);
						}
					}
				}

				// Step 6: Process result - success goes back to the list with a message
				// (redirect, so refreshing won't submit the form again)
				if (added) {
					response.sendRedirect("listParticipants.jsp?msg=added");
					return;
				}
			}
		}
	}
%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Add participant - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
	<main class="page">
		<%@ include file="/shared/header.jsp" %>

		<div class="card">
			<h1 class="pageTitle">Add participant</h1>
			<p class="pageSub">Staff-managed account. Fields marked <span class="req">*</span> are required.</p>

			<%-- submits to the same page; novalidate turns off the browser checks --%>
			<%-- every field is checked by the server-side code above --%>
			<form action="addParticipant.jsp" method="post" novalidate>
				<div class="formGrid">

					<div class="field">
						<label for="username">Username <span class="req">*</span></label>
						<input type="text" id="username" name="username" maxlength="20" placeholder="e.g. alex_tan"
							value="<%= escapeHtml(username) %>" class="<%= usernameErr != null ? "inputError" : "" %>">
						<% if (usernameErr != null) { %><div class="fieldError"><%= usernameErr %></div><% } %>
						<div class="fieldHint">Use 3-20 letters, numbers or underscores.</div>
					</div>

					<div class="field">
						<label for="fullName">Full name <span class="req">*</span></label>
						<input type="text" id="fullName" name="fullName" maxlength="100" placeholder="e.g. Alex Tan"
							value="<%= escapeHtml(fullName) %>" class="<%= fullNameErr != null ? "inputError" : "" %>">
						<% if (fullNameErr != null) { %><div class="fieldError"><%= fullNameErr %></div><% } %>
						<div class="fieldHint">Enter the participant's full name.</div>
					</div>

					<div class="field">
						<label for="contactNum">Contact number <span class="req">*</span></label>
						<input type="text" id="contactNum" name="contactNum" maxlength="9" placeholder="e.g. 9123 4567"
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

				<%-- form-level message, above the buttons --%>
				<% if (formErr != null) { %>
					<div class="msgBox msgError"><%= formErr %></div>
				<% } %>

				<div class="formActions">
					<span></span>
					<span>
						<a class="btn" href="listParticipants.jsp">Cancel</a>
						<input type="submit" class="btn btnDark" value="Save participant">
					</span>
				</div>
			</form>
		</div>
	</main>

	<%-- TODO: shared footer --%>
</body>
</html>