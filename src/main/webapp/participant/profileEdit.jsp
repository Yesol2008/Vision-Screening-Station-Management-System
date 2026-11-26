<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%@ page import="io.github.cdimascio.dotenv.DotenvException" %>
<%--
	Author: Htet Yamin Aung (P2535607)
	Description: ST0510/JAD Assignment 1 - Participant > Edit my profile

	This form submits to ITSELF (action="profileEdit.jsp"):
	    - first visit (GET)       -> load the current details from the database into the form
	    - submitted (POST), bad   -> show the form again with the user's typing kept
	                                 and an error under each wrong field
	    - submitted (POST), good  -> save via the update_my_profile stored procedure,
	                                 then redirect to myProfile.jsp?msg=updated
	Whose profile is edited comes from the session (via the guard), never from the form,
	so a participant can only change their own details. The role cannot be changed here.
--%>
<%@ include file="/auth/participantGuard.jsp" %>
<%
	//read form data as UTF-8
	request.setCharacterEncoding("UTF-8");

	// values shown in the form
	// GET: filled from the database below; POST: what the user typed
	String username = "";
	String fullName = "";
	String contactNum = "";
	String email = "";

	// one error message per field (null means the field has no error)
	String usernameErr = null;
	String fullNameErr = null;
	String contactNumErr = null;
	String emailErr = null;

	// form error: not about one field
	String formErr = null;

	// only run the checks when the form was submitted (when the request method is POST)
	if ("POST".equals(request.getMethod())) {

		// capture the parameter values
		String usernameIn = request.getParameter("username");
		String fullNameIn = request.getParameter("fullName");
		String contactNumIn = request.getParameter("contactNum");
		String emailIn = request.getParameter("email");

		// check for null: if any of the required fields is missing from the request
		if (usernameIn == null || fullNameIn == null || contactNumIn == null || emailIn == null) {
			formErr = "Please fill in all the required fields to proceed.";
		} else {

			// remove spaces at the start and end
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

			// check if there is no error in all fields
			boolean allValid = usernameErr == null && fullNameErr == null
					&& contactNumErr == null && emailErr == null;

			if (!allValid) {
				formErr = "Please correct the highlighted fields. Your other entries have been kept.";
			} else {
				// only touch the database when every field passed
				boolean updated = false;
				Connection conn = null;

				try {
					//Load the JDBC driver
					Class.forName("com.mysql.cj.jdbc.Driver");

					//Read the database connection details from WEB-INF/.env
					Dotenv dotenv = Dotenv.configure()
							.directory(application.getRealPath("/WEB-INF")).load();

					//Connect to the database
					conn = DriverManager.getConnection(dotenv.get("DB_URL"),
							dotenv.get("DB_USERNAME"), dotenv.get("DB_PASSWORD"));

					// check if the new username taken by SOMEONE ELSE?
					// (user_id <> ? skips this user, so keeping one's own username is fine)
					PreparedStatement ps = conn.prepareStatement(
							"SELECT user_id FROM users WHERE username = ? AND user_id <> ?");
					ps.setString(1, username);
					ps.setInt(2, currentUserId);
					ResultSet rs = ps.executeQuery();

					// one row at most (username is UNIQUE), so use if instead of while
					//if username is already used by someone else
					if (rs.next()) {
						usernameErr = "The username is already taken. Please try again with a different username.";
						formErr = "Please correct the highlighted fields. Your other entries have been kept.";
					} else {
						//update users AND participants together in the stored procedure
						// both ids come from the session (via the guard), never from the form
						CallableStatement cs = conn.prepareCall("{ call update_my_profile(?, ?, ?, ?, ?, ?) }");
						cs.setInt(1, currentUserId);
						cs.setInt(2, currentParticipantId);
						cs.setString(3, username);
						cs.setString(4, fullName);
						cs.setString(5, email);
						cs.setString(6, contactNum);

						// Step 5: Execute
						cs.execute();
						updated = true;
					}

				// Catch errors: print details to the console for debugging,
				// but show the user a general message
				} catch (SQLIntegrityConstraintViolationException e) {
					// someone took the same username between the check and the update
					System.err.println("profileEdit.jsp - duplicate username :" + e);
					usernameErr = "The username is already taken. Please try again with a different username.";
					formErr = "Please correct the highlighted fields. Your other entries have been kept.";
				} catch (ClassNotFoundException e) {
					System.err.println("profileEdit.jsp - JDBC driver not found :" + e);
					formErr = "Sorry, your profile couldn't be saved right now. Please try again later.";
				} catch (SQLException e) {
					System.err.println("profileEdit.jsp - database error :" + e);
					formErr = "Sorry, your profile couldn't be saved right now. Please try again later.";
				} catch (DotenvException e) {
					System.err.println("profileEdit.jsp - .env file error :" + e);
					formErr = "Sorry, your profile couldn't be saved right now. Please try again later.";
				} catch (Exception e) {
					System.err.println("profileEdit.jsp - unexpected error :" + e);
					formErr = "Sorry, your profile couldn't be saved right now. Please try again later.";
				} finally {
					//Close the connection
					if (conn != null) {
						try {
							conn.close();
						} catch (SQLException e) {
							System.err.println("Error closing connection :" + e);
						}
					}
				}

				// Process result - success goes back to My profile with a message
				// (redirect, so refreshing won't submit the form again)
				if (updated) {
					response.sendRedirect("myProfile.jsp?msg=updated");
					return;
				}
			}
		}

	} else {
		// ===== first visit (GET): fill the form with the current details =====
		Connection conn = null;

		try {
			//Load the JDBC driver
			Class.forName("com.mysql.cj.jdbc.Driver");

			//Read the database connection details from WEB-INF/.env
			Dotenv dotenv = Dotenv.configure()
					.directory(application.getRealPath("/WEB-INF")).load();

			//Connect to the database
			conn = DriverManager.getConnection(dotenv.get("DB_URL"),
					dotenv.get("DB_USERNAME"), dotenv.get("DB_PASSWORD"));

			//find the profile by the userId from the session
			PreparedStatement ps = conn.prepareStatement(
					"SELECT u.username, p.full_name, p.contact_number, p.email "
					+ "FROM participants p JOIN users u ON p.user_id = u.user_id "
					+ "WHERE p.user_id = ?");
			ps.setInt(1, currentUserId);

			//Execute
			ResultSet rs = ps.executeQuery();

			//Process result - one row at most (user_id is UNIQUE in participants)
			if (rs.next()) {
				username = rs.getString("username");
				fullName = rs.getString("full_name");
				contactNum = rs.getString("contact_number");
				email = rs.getString("email");

				// columns that may be NULL in the database become empty boxes
				if (contactNum == null) {
					contactNum = "";
				}
				if (email == null) {
					email = "";
				}
			} else {
				formErr = "Your profile could not be found.";
			}

		} catch (ClassNotFoundException e) {
			System.err.println("profileEdit.jsp - JDBC driver not found :" + e);
			formErr = "Sorry, your current details couldn't be loaded. Please try again later.";
		} catch (SQLException e) {
			System.err.println("profileEdit.jsp - database error :" + e);
			formErr = "Sorry, your current details couldn't be loaded. Please try again later.";
		} catch (DotenvException e) {
			System.err.println("profileEdit.jsp - .env file error :" + e);
			formErr = "Sorry, your current details couldn't be loaded. Please try again later.";
		} catch (Exception e) {
			System.err.println("profileEdit.jsp - unexpected error :" + e);
			formErr = "Sorry, your current details couldn't be loaded. Please try again later.";
		} finally {
			//Close the connection
			if (conn != null) {
				try {
					conn.close();
				} catch (SQLException e) {
					System.err.println("Error closing connection :" + e);
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
	<title>Edit my profile - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>

<div class="page">

	<%--  shared header for signed-in users --%>
	<%@ include file="/shared/header.jsp" %>

	<div class="card">
		<h1 class="pageTitle">Edit my profile</h1>
		<p class="pageSub"><%= escapeHtml(currentUsername) %> &middot; Participant &middot; Fields marked <span class="req">*</span> are required.</p>

		<%-- submits to the same page; novalidate turns off the browser checks --%>
		<%-- every field is checked by the server-side code above --%>
		<%-- error is placed right before the hint so styles.css can hide the hint when an error shows --%>
		<form action="profileEdit.jsp" method="post" novalidate>
			<div class="formGrid">
				<div class="field">
					<label for="username">Username <span class="req">*</span></label>
					<input type="text" id="username" name="username" maxlength="20"
						value="<%= escapeHtml(username) %>" class="<%= usernameErr != null ? "inputError" : "" %>">
					<% if (usernameErr != null) { %><div class="fieldError"><%= usernameErr %></div><% } %>
					<div class="fieldHint">Use 3-20 letters, numbers or underscores.</div>
				</div>

				<div class="field">
					<label for="fullName">Full name <span class="req">*</span></label>
					<input type="text" id="fullName" name="fullName" maxlength="100"
						value="<%= escapeHtml(fullName) %>" class="<%= fullNameErr != null ? "inputError" : "" %>">
					<% if (fullNameErr != null) { %><div class="fieldError"><%= fullNameErr %></div><% } %>
					<div class="fieldHint">Enter your full name.</div>
				</div>

				<div class="field">
					<label for="contactNum">Contact number <span class="req">*</span></label>
					<input type="text" id="contactNum" name="contactNum" maxlength="9"
						value="<%= escapeHtml(contactNum) %>" class="<%= contactNumErr != null ? "inputError" : "" %>">
					<% if (contactNumErr != null) { %><div class="fieldError"><%= contactNumErr %></div><% } %>
					<div class="fieldHint">8-digit Singapore number starting with 6, 8 or 9.</div>
				</div>

				<div class="field">
					<label for="email">Email <span class="req">*</span></label>
					<input type="text" id="email" name="email" maxlength="255"
						value="<%= escapeHtml(email) %>" class="<%= emailErr != null ? "inputError" : "" %>">
					<% if (emailErr != null) { %><div class="fieldError"><%= emailErr %></div><% } %>
					<div class="fieldHint">We'll use this email to contact you about your screening.</div>
				</div>

			</div>

			<%-- form-level message, above the buttons --%>
			<% if (formErr != null) { %>
				<div class="msgBox msgError"><%= formErr %></div>
			<% } %>

			<div class="formActions">
			<%-- separate page, so the password is never part of the profile form --%>
			<a class="btn" href="updatePwd.jsp">Change password</a>
				<span>
					<a class="btn" href="myProfile.jsp">Cancel</a>
					<input type="submit" class="btn btnDark" value="Save profile">
				</span>
			</div>
		</form>
	</div>	     
	<%@ include file="/shared/footer.html" %>
</div>
</body>
</html>
