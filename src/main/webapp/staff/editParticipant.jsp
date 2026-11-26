<%--
Author: Htet Yamin Aung (P2535607)
Date: 23/11/2026
Description: ST0510/JAD Assignment 1 - Staff: edit a participant's details

This form submits to ITSELF (action="editParticipant.jsp"):
	- first visit (GET)       -> load the participant's current details into the form
	- submitted (POST), bad   -> show the form again with the typing kept and an error under each wrong field
	- submitted (POST), good  -> save via the update_my_profile stored procedure,
	                             then redirect to listParticipants.jsp?msg=updated
The participant id comes from a hidden field, so it is checked like any other user input.
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv, io.github.cdimascio.dotenv.DotenvException" %>

<%-- staff only page --%>
<%@ include file="/auth/staffGuard.jsp" %>
<%
	//read form data as UTF-8
	request.setCharacterEncoding("UTF-8");

	//1. the id arrives as text: from the Edit button (GET) or the hidden field in this form (POST)
	String idText = request.getParameter("id");

	if (idText == null) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	int participantId;
	try {
		participantId = Integer.parseInt(idText.trim());
	} catch (NumberFormatException e) {
		response.sendRedirect("listParticipants.jsp?errCode=invalidId");
		return;
	}

	// values shown in the form
	// GET: filled from the database below; POST: what the staff member typed
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

	// set when no participant has this id; the redirect happens after the connection is closed
	boolean notFound = false;

	//2. only run the checks when the form was submitted (when the request method is POST)
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
					// Step 1: Load JDBC Driver
					Class.forName("com.mysql.cj.jdbc.Driver");

					// Step 2: Read connection details from .env in WEB-INF
					Dotenv dotenv = Dotenv.configure().directory(application.getRealPath("/WEB-INF")).load();
					String connURL = dotenv.get("DB_URL");
					String dbUser = dotenv.get("DB_USERNAME");
					String dbPassword = dotenv.get("DB_PASSWORD");

					// Step 3: Establish connection
					conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

					// Step 4a: find the participant's user_id (the form only sends the participant_id)
					PreparedStatement findPs = conn.prepareStatement(
							"SELECT user_id FROM participants WHERE participant_id = ?");
					findPs.setInt(1, participantId);
					ResultSet findRs = findPs.executeQuery();

					if (!findRs.next()) {
						notFound = true;
					} else {
						int userId = findRs.getInt("user_id");

						// Step 4b: is the new username taken by SOMEONE ELSE?
						// (user_id <> ? skips this participant, so keeping the same username is fine)
						PreparedStatement checkPs = conn.prepareStatement(
								"SELECT user_id FROM users WHERE username = ? AND user_id <> ?");
						checkPs.setString(1, username);
						checkPs.setInt(2, userId);
						ResultSet checkRs = checkPs.executeQuery();

						// one row at most (username is UNIQUE), so use if instead of while
						if (checkRs.next()) {
							usernameErr = "The username is already taken. Please try again with a different username.";
							formErr = "Please correct the highlighted fields. Your other entries have been kept.";
						} else {
							// Step 4c: update users AND participants together in the stored procedure
							CallableStatement cs = conn.prepareCall("{ call update_my_profile(?, ?, ?, ?, ?, ?) }");
							cs.setInt(1, userId);
							cs.setInt(2, participantId);
							cs.setString(3, username);
							cs.setString(4, fullName);
							cs.setString(5, email);
							cs.setString(6, contactNum);

							// Step 5: Execute
							cs.execute();
							updated = true;
						}
					}

				} catch (SQLIntegrityConstraintViolationException e) {
					// someone took the same username between the check and the update
					System.err.println("editParticipant.jsp - duplicate username: " + e);
					usernameErr = "The username is already taken. Please try again with a different username.";
					formErr = "Please correct the highlighted fields. Your other entries have been kept.";
				} catch (ClassNotFoundException e) {
					System.err.println("editParticipant.jsp - driver not found: " + e);
					formErr = "Sorry, the changes couldn't be saved right now. Please try again later.";
				} catch (SQLException e) {
					System.err.println("editParticipant.jsp - SQL error: " + e);
					formErr = "Sorry, the changes couldn't be saved right now. Please try again later.";
				} catch (DotenvException e) {
					System.err.println("editParticipant.jsp - .env error: " + e);
					formErr = "Sorry, the changes couldn't be saved right now. Please try again later.";
				} catch (Exception e) {
					System.err.println("editParticipant.jsp - " + e);
					formErr = "Sorry, the changes couldn't be saved right now. Please try again later.";
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
				if (updated) {
					response.sendRedirect("listParticipants.jsp?msg=updated");
					return;
				}
			}
		}

	} else {
		//3. first visit (GET): fill the form with the participant's current details
		Connection conn = null;

		try {
			//Load JDBC Driver
			Class.forName("com.mysql.cj.jdbc.Driver");

			// Read connection details from .env in WEB-INF
			Dotenv dotenv = Dotenv.configure().directory(application.getRealPath("/WEB-INF")).load();
			String connURL = dotenv.get("DB_URL");
			String dbUser = dotenv.get("DB_USERNAME");
			String dbPassword = dotenv.get("DB_PASSWORD");

			//Establish connection
			conn = DriverManager.getConnection(connURL, dbUser, dbPassword);

			//PreparedStatement; the id came from the browser, so it goes in through ?
			PreparedStatement ps = conn.prepareStatement(
					"SELECT u.username, p.full_name, p.contact_number, p.email "
					+ "FROM participants p JOIN users u ON p.user_id = u.user_id "
					+ "WHERE p.participant_id = ?");
			ps.setInt(1, participantId);

			//Execute query
			ResultSet rs = ps.executeQuery();

			//Process result - if, not while: an id matches one row at most
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
				notFound = true;
			}

		} catch (ClassNotFoundException e) {
			System.err.println("editParticipant.jsp - driver not found: " + e);
			response.sendRedirect("listParticipants.jsp?errCode=dbError");
			return;
		} catch (SQLException e) {
			System.err.println("editParticipant.jsp - SQL error: " + e);
			response.sendRedirect("listParticipants.jsp?errCode=dbError");
			return;
		} catch (DotenvException e) {
			System.err.println("editParticipant.jsp - .env error: " + e);
			response.sendRedirect("listParticipants.jsp?errCode=dbError");
			return;
		} catch (Exception e) {
			System.err.println("editParticipant.jsp - " + e);
			response.sendRedirect("listParticipants.jsp?errCode=dbError");
			return;
		} finally {
			//Close connection
			if (conn != null) {
				try {
					conn.close();
				} catch (SQLException e) {
					System.err.println("Error closing connection: " + e);
				}
			}
		}
	}

	//4. valid number, but no participant with that id
	if (notFound) {
		response.sendRedirect("listParticipants.jsp?errCode=notFound");
		return;
	}
%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Edit participant - Vision Screening</title>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head>
<body>
	<main class="page">
		<%@ include file="/shared/header.jsp" %>

		<div class="card">
			<h1 class="pageTitle">Edit participant</h1>
			<p class="pageSub">P<%= twoDigits(participantId) %> &middot; Fields marked <span class="req">*</span> are required.</p>

			<%-- submits to the same page; novalidate turns off the browser checks --%>
			<%-- every field is checked by the server-side code above --%>
			<form action="editParticipant.jsp" method="post" novalidate>
				<%-- the id travels with the form so the POST knows which participant to update --%>
				<input type="hidden" name="id" value="<%= participantId %>">

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
						<div class="fieldHint">Enter the participant's full name.</div>
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
						<input type="submit" class="btn btnDark" value="Save changes">
					</span>
				</div>
			</form>
		</div>
		<%@ include file="/shared/footer.html" %>
	</main>
</body>
</html>